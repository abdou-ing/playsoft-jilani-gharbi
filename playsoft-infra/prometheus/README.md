# K8s Auto-Scaling Pipeline — Prometheus + Hetzner Cloud

Monitors CPU on Kubernetes nodes and automatically provisions new worker nodes when load is critical.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Bastion Host                         │
│                                                         │
│  Prometheus :9090 ──► Alertmanager :9093               │
│       │                     │                           │
│  Scrapes node_exporter       │ webhook (severity=critical│
│  on all k8s nodes            │ action=scale-out)        │
│                              ▼                           │
│                    Autoscaler :8080                      │
│                         │                               │
│               ┌──────────┼──────────┐                   │
│               ▼          ▼          ▼                   │
│           Terraform   Ansible   Prometheus              │
│           (create     (join     (add new                │
│            node)       k8s)      target)                │
└─────────────────────────────────────────────────────────┘
         │
         ▼ Private network 10.20.0.0/24
┌────────────────────┐
│  10.20.0.10        │  k8s master
│  10.20.0.11        │  worker-1
│  10.20.0.12        │  worker-2  ← created on scale-out
│  ...               │
└────────────────────┘
```

### Alert → Scale-out flow

1. `node_exporter` exposes CPU metrics on every node at `:9100`
2. Prometheus scrapes them every 15s and evaluates alert rules
3. If CPU > 85% for 2 minutes → `NodeCPUCritical` fires with `action=scale-out`
4. Alertmanager routes it to the autoscaler webhook at `http://localhost:8080`
5. The webhook:
   - Reads current worker count from Terraform state
   - Runs `terraform apply -var worker_count=N+1` to create the new node on Hetzner
   - Waits for SSH to become available
   - Waits for cloud-init + reboot to fully complete
   - Runs Ansible to install k8s packages and join the node to the cluster
   - Adds the new node's IP to `prometheus.yml` and reloads Prometheus
6. A 10-minute cooldown prevents repeated scale-outs

---

## Project Structure

```
prometheus/
├── config/
│   ├── prometheus.yml       # Scrape config (updated dynamically on scale-out)
│   ├── alerts.yml           # Alert rules (NodeCPUWarning, NodeCPUCritical)
│   └── alertmanager.yml     # Routes critical alerts to autoscaler webhook
├── systemd/
│   ├── alertmanager.service # Systemd unit — routes critical alerts to autoscaler webhook
│   └── autoscaler.service   # Systemd unit — template, HCLOUD_TOKEN injected by Ansible at deploy time
├── webhook/
│   └── webhook.py           # Autoscaler — listens on :8080, drives scale-out
├── ansible/
│   └── join-worker.yml      # Installs k8s packages and joins node to cluster
├── terraform/
│   ├── main.tf              # Uses k8s-worker module, references nw-jilani network
│   ├── outputs.tf           # worker_private_ips, master_private_ip
│   ├── provider.tf          # Hetzner provider (token from HCLOUD_TOKEN env var)
│   ├── variables.tf
│   ├── env/dev.tfvars       # location, server_type, worker_count, IPs
│   └── modules/k8s-worker/
│       ├── main.tf          # hcloud_server.worker[count]
│       ├── outputs.tf       # worker_private_ips via cidrhost()
│       ├── variables.tf
│       └── cloud-init.yaml  # Sets up networking, removes hc-utils, reboots
└── deploy.sh                # One-shot setup script
```

---

## Services

### `alertmanager.service`
Receives alerts from Prometheus and routes them to the autoscaler.
- Listens on `:9093`
- Receives `NodeCPUCritical` alerts from Prometheus (CPU > 85% for 2 min)
- Deduplicates and groups alerts to avoid spam
- Routes alerts with `severity=critical` + `action=scale-out` to `POST http://localhost:8080/alert`

### `autoscaler.service`
The automation engine — listens for alerts and drives the full scale-out sequence.
- Listens on `:8080` for POST requests from AlertManager
- On a `scale-out` alert:
  1. Reads current worker count from Terraform state
  2. Runs `terraform apply -var worker_count=N+1` → creates new VM on Hetzner
  3. Waits for SSH + cloud-init + reboot to complete
  4. Runs `ansible-playbook join-worker.yml` → installs k8s packages and joins node to cluster
  5. Updates `prometheus.yml` to scrape the new node and reloads Prometheus
- Enforces a 10-minute cooldown between scale-outs to prevent runaway provisioning

---

## Master Node Setup

SSH into the master before running `deploy.sh` on the bastion:

```bash
ssh -i /root/.ssh/jilani root@10.20.0.10
```

### 1. Install and start node_exporter

Prometheus scrapes the master at `:9100` — it must be running:

```bash
apt install -y prometheus-node-exporter
systemctl enable --now prometheus-node-exporter
systemctl is-active prometheus-node-exporter   # should print: active
```

### 2. Verify kubeadm is initialised

```bash
kubectl get nodes
```

The master should appear as `Ready`. If not, run `kubeadm init` before proceeding.

> **Note:** Everything else (Terraform, Ansible, Prometheus, Alertmanager, autoscaler) runs on the **bastion**, not the master. The master only needs `node_exporter` running and `kubeadm` already initialised as prerequisites.

---

## Prerequisites

### On Hetzner Cloud (must exist before deploy)

| Resource | Name | Notes |
|---|---|---|
| Private network | `nw-jilani` | CIDR `10.20.0.0/24`, gateway `10.20.0.1` |
| SSH key | `jilani-key` | Uploaded to Hetzner, private key at `/root/.ssh/jilani` on bastion |
| k8s master | `hzn-k8s-master-jilani` | Already running at `10.20.0.10`, kubeadm initialised |
| node_exporter | running on master | Listening on `:9100` |
| Snapshot image | label `created_by=jilani,role=k8s_master_and_worker` | Base image for workers |

### On the Bastion Host

Install the following before running `deploy.sh`:

```bash
# Prometheus
apt install -y prometheus

# Alertmanager
wget https://github.com/prometheus/alertmanager/releases/download/v0.32.1/alertmanager-0.32.1.linux-amd64.tar.gz
tar xzf alertmanager-0.32.1.linux-amd64.tar.gz
cp alertmanager-0.32.1.linux-amd64/alertmanager /usr/local/bin/
mkdir -p /var/lib/alertmanager

# Terraform
apt install -y terraform   # or install manually from releases.hashicorp.com

# Ansible
apt install -y ansible

# Python 3 (for webhook)
apt install -y python3

# stress (for testing)
apt install -y stress
```

---

## Setup from Scratch

### 1. Clone / copy project files

```bash
mkdir -p /opt/infra/prometheus
# copy all project files to /opt/infra/prometheus/
```

### 2. Set your Hetzner token

```bash
export HCLOUD_TOKEN="your-64-character-hetzner-api-token"
```

### 3. Run Ansible from your local machine

```bash
cd playsoft-infra/ansible
ansible-playbook -i inventory.ini site.yml --limit bastion --tags autoscaler
```

This playbook:
- Copies all project files to `/opt/infra/prometheus/` on the bastion
- Templates `autoscaler.service` with `HCLOUD_TOKEN` read from your local env var
- Installs and starts the autoscaler systemd unit

### 4. Import existing worker into Terraform state (if worker already exists)

If worker-1 was created outside of this Terraform (e.g. manually or by another config), import it before the first scale-out otherwise Terraform will destroy and recreate it:

```bash
# Get the server ID from Hetzner API
curl -s -H "Authorization: Bearer $HCLOUD_TOKEN" \
  "https://api.hetzner.cloud/v1/servers?name=hzn-k8s-worker-1-jilani" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['servers'][0]['id'])"

# Import into state (replace 123456789 with the real ID)
cd /opt/infra/prometheus/terraform
terraform import -var-file=env/dev.tfvars \
  'module.k8s_cluster.hcloud_server.worker[0]' 123456789
```

### 5. Verify all services are running

```bash
systemctl is-active prometheus alertmanager autoscaler
```

All three should return `active`.

### 6. Verify Prometheus is scraping

Open in browser: `http://<bastion-ip>:9090/targets`

Both nodes should show `UP`.

---

## Configuration

### Alert thresholds — [config/alerts.yml](config/alerts.yml)

| Alert | Threshold | Duration | Action |
|---|---|---|---|
| `NodeCPUWarning` | CPU > 70% | 2 min | none (informational) |
| `NodeCPUCritical` | CPU > 85% | 2 min | triggers scale-out |

### Autoscaler settings — [webhook/webhook.py](webhook/webhook.py)

| Variable | Value | Description |
|---|---|---|
| `COOLDOWN` | 600s | Minimum time between scale-outs |
| `MASTER_IP` | `10.20.0.10` | Used as SSH jump host for Ansible |
| `WORKER_BASE_IP` | 11 | First worker gets `.11`, second `.12`, etc. |

### Worker node size — [terraform/env/dev.tfvars](terraform/env/dev.tfvars)

```hcl
server_type = "cx23"   # 2 vCPU, 4 GB RAM
location    = "nbg1"   # Nuremberg
worker_count = 1       # starting count
```

---

## Testing

### Trigger a scale-out

SSH to the master and spike the CPU:

```bash
ssh -i /root/.ssh/jilani root@10.20.0.10 "stress --cpu 4 --timeout 360"
```

### Watch the pipeline live

```bash
journalctl -u autoscaler -f
```

Expected log sequence:

```
INFO Scale-out triggered by 10.20.0.10:9100
INFO Scaling 1 → 2 workers, new IP: 10.20.0.12
INFO Terraform stdout: Apply complete! Resources: 1 added...
INFO Waiting for SSH on 10.20.0.12 ...
INFO Waiting for cloud-init + reboot on 10.20.0.12 ...
INFO Reboot detected on 10.20.0.12, waiting for SSH to recover ...
INFO Ansible stdout: ... ok=6 changed=3 unreachable=0 failed=0 ...
INFO Prometheus updated — scraping 2 worker(s)
```

### Verify node joined the cluster

```bash
ssh -i /root/.ssh/jilani root@10.20.0.10 "kubectl get nodes"
```

### Monitor in the browser

| URL | Purpose |
|---|---|
| `http://<bastion-ip>:9090` | Prometheus — targets, alerts, rules |
| `http://<bastion-ip>:9093` | Alertmanager — active alerts, routing |

### Reset to 1 worker for re-testing

```bash
# 1. Drain and remove the node from k8s
ssh -i /root/.ssh/jilani root@10.20.0.10 \
  "kubectl drain hzn-k8s-worker-2-jilani --ignore-daemonsets --delete-emptydir-data && \
   kubectl delete node hzn-k8s-worker-2-jilani"

# 2. Scale Terraform back to 1 worker
cd /opt/infra/prometheus/terraform
terraform apply -auto-approve -var-file=env/dev.tfvars -var=worker_count=1
```

---

## Troubleshooting

### Alertmanager fails to start — `port 9094 already in use`

A stale `prometheus-alertmanager` process is holding the port. Find and kill it:

```bash
ss -tlnp | grep 9094          # find the PID
kill <PID>
systemctl start alertmanager
```

### Scale-out fails — `Output "worker_private_ips" not found`

Terraform state is empty. Import the existing worker first (see Setup step 4).

### Ansible fails — `nodes "k8s-worker-N" not found`

The node joined with a different hostname than the Ansible inventory name. The playbook uses `ansible_hostname` (the real system hostname) — verify the worker's hostname matches what `kubectl get nodes` shows:

```bash
ssh -i /root/.ssh/jilani -o ProxyJump=root@10.20.0.10 root@10.20.0.12 "hostname"
ssh -i /root/.ssh/jilani root@10.20.0.10 "kubectl get nodes"
```

### Worker stuck in `NotReady`

Usually resolves itself within 1-2 minutes after cloud-init completes. Check kubelet logs on the worker:

```bash
ssh -i /root/.ssh/jilani -o ProxyJump=root@10.20.0.10 root@10.20.0.11 \
  "journalctl -u kubelet -n 30"
```

### Scale-out keeps creating worker-3 instead of worker-2

Worker-2 was deleted manually from Hetzner without going through Terraform. The state is out of sync. Reconcile it:

```bash
cd /opt/infra/prometheus/terraform
terraform apply -auto-approve -var-file=env/dev.tfvars -var=worker_count=1
```

---

## Sensitive Data

| Secret | Location | How it's handled |
|---|---|---|
| `HCLOUD_TOKEN` | `systemd/autoscaler.service` on bastion | Never stored in the repo — Ansible reads it from the local `HCLOUD_TOKEN` env var at deploy time via `lookup('env', 'HCLOUD_TOKEN')` and writes it directly into the systemd unit |
| SSH private key | `/root/.ssh/jilani` on bastion | Not stored in the repo |

**Never commit the real token to git.** Export it in your shell before running Ansible:

```bash
export HCLOUD_TOKEN="your-token"
ansible-playbook -i inventory.ini site.yml --limit bastion --tags autoscaler
```
