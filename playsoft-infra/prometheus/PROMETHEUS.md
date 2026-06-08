# Prometheus Autoscaling Pipeline — Full Reference

## Overview

This pipeline runs on a **Hetzner Cloud bastion server** (`188.245.215.21`) and does three things automatically:

1. **Monitors** all Kubernetes nodes with Prometheus + node_exporter
2. **Alerts** by email (Alertmanager) when something is wrong
3. **Scales** the cluster up or down (Terraform + Ansible) based on CPU load

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Bastion 188.245.215.21                  │
│                                                         │
│  ┌───────────┐   scrape    ┌──────────────────────────┐ │
│  │ Prometheus│ ──────────► │  targets.json (dynamic)  │ │
│  │  :9090    │             │  master  10.20.0.10:9100  │ │
│  └─────┬─────┘             │  worker1 10.20.0.11:9100  │ │
│        │ alert             │  worker2 10.20.0.12:9100  │ │
│        ▼                   └──────────────────────────┘ │
│  ┌─────────────┐                                        │
│  │ Alertmanager│ ──► email (jilanigharbi88@gmail.com)   │
│  │   :9093     │ ──► webhook (localhost:8080)           │
│  └─────────────┘                                        │
│        │                                                │
│        ▼                                                │
│  ┌─────────────┐   terraform apply   ┌───────────────┐  │
│  │  Autoscaler │ ──────────────────► │ Hetzner Cloud │  │
│  │  webhook.py │                     │  (new worker) │  │
│  │   :8080     │   ansible-playbook  └───────────────┘  │
│  └─────────────┘ ──────────────────► join-worker.yml    │
└─────────────────────────────────────────────────────────┘

Private network: 10.20.0.0/24
  Master  → 10.20.0.10
  Worker1 → 10.20.0.11
  Worker2 → 10.20.0.12  (created on scale-out)
  WorkerN → 10.20.0.(10+N)
```

---

## File Structure

```
playsoft-infra/
├── ansible/
│   ├── inventory.ini                        # bastion host entry
│   ├── site.yml                             # main playbook (tag: autoscaler)
│   └── roles/autoscaler/
│       ├── vars/main.yml                    # version pins and paths
│       ├── tasks/main.yml                   # full deployment tasks
│       ├── handlers/main.yml                # service reload handlers
│       ├── files/
│       │   ├── alertmanager.service         # systemd unit for alertmanager
│       │   └── prometheus-override.conf     # overrides prometheus config path
│       └── templates/
│           ├── alertmanager.yml.j2          # alertmanager routing + email config
│           └── autoscaler.service.j2        # systemd unit for webhook.py
└── prometheus/
    ├── config/
    │   ├── prometheus.yml                   # scrape config
    │   ├── alerts.yml                       # all alert rules
    │   └── targets.json                     # dynamic scrape targets (auto-updated)
    ├── webhook/
    │   └── webhook.py                       # autoscaler webhook server
    ├── ansible/
    │   └── join-worker.yml                  # joins new worker into k8s cluster
    └── terraform/
        ├── main.tf                          # calls k8s-worker module
        ├── variables.tf                     # location, server_type, worker_count
        ├── outputs.tf                       # exposes worker IPs
        └── modules/k8s-worker/
            └── main.tf                      # hcloud_server resource definition
```

On the bastion, all files are deployed to `/opt/infra/prometheus/`.

---

## Services on the Bastion

| Service | Binary | Port | Config |
|---|---|---|---|
| `prometheus` | `/usr/bin/prometheus` | `9090` | `/opt/infra/prometheus/config/prometheus.yml` |
| `alertmanager` | `/usr/local/bin/alertmanager` | `9093` | `/opt/infra/prometheus/config/alertmanager.yml` |
| `autoscaler` | `/usr/bin/python3 webhook.py` | `8080` | env from `/etc/autoscaler/env` |

Check status:
```bash
systemctl status prometheus alertmanager autoscaler
```

Logs:
```bash
journalctl -fu autoscaler
journalctl -fu alertmanager
```

---

## 1. Prometheus

**Config:** `prometheus/config/prometheus.yml`

```yaml
global:
  scrape_interval: 15s       # pull metrics every 15s
  evaluation_interval: 15s   # evaluate alert rules every 15s

rule_files:
  - /opt/infra/prometheus/config/alerts.yml

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['localhost:9093']

scrape_configs:
  - job_name: k8s-nodes
    file_sd_configs:
      - files:
          - /opt/infra/prometheus/config/targets.json
        refresh_interval: 30s   # re-read targets.json every 30s
```

**Key point:** Prometheus does not have a static list of nodes. It reads `targets.json` every 30 seconds, so any change to that file is picked up automatically — no restart needed.

**systemd override** (`files/prometheus-override.conf`) makes prometheus read config from `/opt/infra/prometheus/` instead of the apt default path:

```ini
[Service]
ExecStart=
ExecStart=/usr/bin/prometheus \
  --config.file=/opt/infra/prometheus/config/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/data \
  ...
```

---

## 2. targets.json — Dynamic Node Discovery

**Path on bastion:** `/opt/infra/prometheus/config/targets.json`

This file is the bridge between the autoscaler and Prometheus. It is written by `webhook.py` and read by Prometheus every 30 seconds.

**Format:**
```json
[
  {"targets": ["10.20.0.10:9100"], "labels": {"job": "k8s-nodes", "nodename": "hzn-k8s-master-jilani"}},
  {"targets": ["10.20.0.11:9100"], "labels": {"job": "k8s-nodes", "nodename": "hzn-k8s-worker-1-jilani"}}
]
```

The `nodename` label is used in alert messages instead of raw IP addresses.

**Who writes it:**

| Trigger | Function | What it does |
|---|---|---|
| Startup | `discover_from_hcloud()` | Queries Hetzner API, builds full node list |
| Every 60s | `sync_loop()` | Keeps targets in sync with actual Hetzner servers |
| Scale-out | `update_prometheus(new_count)` | Adds the new worker IP |
| Scale-in | `update_prometheus(new_count)` | Removes the worker IP **before** draining |

**Discovery rules in `sync_loop`:**
- Server exists in Hetzner + already in targets → **keep** (even if node_exporter is down)
- Server exists in Hetzner + not in targets → **add only if node_exporter is responding**
- Server deleted from Hetzner → **remove**

This prevents false `NodeDown` alerts when a new node is still provisioning or when a node has a temporary network blip.

---

## 3. Alert Rules

**Config:** `prometheus/config/alerts.yml`

All alerts use `nodename` in the summary so emails show the server name, not the IP.

### CPU Alerts

| Alert | Condition | For | Action |
|---|---|---|---|
| `NodeCPUWarning` | CPU > 70% | 2m | Email only |
| `NodeCPUCritical` | CPU > 85% | 2m | Email + **scale-out** |
| `NodeCPULow` | Cluster avg CPU < 20% | 10m | Email + **scale-in** |

### Availability

| Alert | Condition | For | Action |
|---|---|---|---|
| `NodeDown` | `up == 0` for any k8s-nodes target | 1m | Email only |

### Memory

| Alert | Condition | For | Action |
|---|---|---|---|
| `NodeMemoryWarning` | RAM used > 80% | 2m | Email only |
| `NodeMemoryCritical` | RAM used > 90% | 2m | Email only |

### Disk

| Alert | Condition | For | Action |
|---|---|---|---|
| `NodeDiskWarning` | Disk `/` > 75% | 5m | Email only |
| `NodeDiskCritical` | Disk `/` > 90% | 5m | Email only |

**Scale-out is triggered by the label `action: scale-out`** on `NodeCPUCritical`.  
**Scale-in is triggered by the label `action: scale-in`** on `NodeCPULow`.

---

## 4. Alertmanager

**Config:** `ansible/roles/autoscaler/templates/alertmanager.yml.j2`  
**Deployed to:** `/opt/infra/prometheus/config/alertmanager.yml`

### Routing

```
All alerts
  └── default route → email receiver
        ├── severity=critical + action=scale-out → autoscaler receiver (repeat: 15m)
        └── action=scale-in                      → autoscaler receiver (repeat: 20m)
```

### Receivers

**`default`** — email to `jilanigharbi88@gmail.com`:
- Sends on firing AND resolved (`send_resolved: true`)
- Custom HTML template: colored card (red for firing, green for resolved), clean table with node name, severity, timestamps
- Subject: `[FIRING] Node Unreachable — hzn-k8s-worker-1-jilani`

**`autoscaler`** — HTTP POST to `localhost:8080`:
- Does NOT send on resolved (`send_resolved: false`)
- Triggers `webhook.py` to run scale-out or scale-in

### Reload alertmanager config (without Ansible)

```bash
# on bastion
systemctl restart alertmanager

# or from local machine
scp -i ~/.ssh/jilani /tmp/alertmanager.yml root@188.245.215.21:/opt/infra/prometheus/config/alertmanager.yml
ssh -i ~/.ssh/jilani root@188.245.215.21 "systemctl restart alertmanager"
```

---

## 5. Autoscaler Webhook (`webhook.py`)

**Deployed to:** `/opt/infra/prometheus/webhook/webhook.py`  
**Runs as:** systemd service `autoscaler`, reads `HCLOUD_TOKEN` from `/etc/autoscaler/env`

### Scale-Out Flow (CPU > 85% for 2 min)

```
Alertmanager POST /
  → webhook reads action=scale-out
  → get current worker count from terraform output
  → terraform apply -var worker_count=N+1       (creates new Hetzner server)
  → wait for SSH on new IP
  → wait for cloud-init + reboot to finish
  → ansible-playbook join-worker.yml            (installs kubeadm, joins cluster)
  → update_prometheus(N+1)                      (adds new IP to targets.json)
```

### Scale-In Flow (Cluster avg CPU < 20% for 10 min)

```
Alertmanager POST /
  → webhook reads action=scale-in
  → skip if already at 1 worker (minimum)
  → update_prometheus(N-1)     ← removes IP FIRST (prevents NodeDown alert)
  → kubectl drain <node>
  → kubectl delete node <node>
  → terraform apply -var worker_count=N-1
```

**Cooldown:** 600 seconds (10 min) between any scale operations.

**Background sync thread** runs every 60 seconds to reconcile `targets.json` with the real Hetzner inventory via the API.

### Token Security

The `HCLOUD_TOKEN` is **never** in the service unit file or environment variables visible in `ps`. It lives in:

```
/etc/autoscaler/env   (mode 0600, owner root)
```

The systemd unit loads it with `EnvironmentFile=/etc/autoscaler/env`.

---

## 6. Terraform

**Source:** `prometheus/terraform/`  
**Deployed to:** `/opt/infra/prometheus/terraform/` on bastion

Manages **worker nodes only**. The master is pre-existing and not managed by Terraform.

**Key variable:** `worker_count` — changed at runtime by `webhook.py` via `terraform apply -var worker_count=N`.

**Worker naming:** `hzn-k8s-worker-{N}-jilani`  
**Worker IPs:** `10.20.0.11`, `10.20.0.12`, ... (sequential, no DHCP)  
**Image:** latest Hetzner snapshot with selector `created_by=jilani,role=k8s_master_and_worker`

---

## 7. Ansible Autoscaler Role

**Playbook:** `ansible/site.yml --tags autoscaler`  
**Inventory:** `ansible/inventory.ini` (bastion group)

**What the role does (in order):**

1. Assert `HCLOUD_TOKEN` is set on the control node
2. Install HashiCorp apt repo (for Terraform)
3. Install `prometheus`, `ansible`, `terraform` via apt
4. Download and install Alertmanager binary (v0.32.1)
5. Create `/etc/autoscaler/` (mode 0700) and write the token to `env` (mode 0600)
6. Create `/opt/infra/prometheus/` directory tree
7. Copy `webhook.py`, `prometheus.yml`, `alerts.yml`, `join-worker.yml`, Terraform files
8. Template `alertmanager.yml` from `alertmanager.yml.j2`
9. Create systemd override for prometheus (point to custom config path)
10. Install `autoscaler.service` and `alertmanager.service` systemd units
11. Generate initial `targets.json` from Terraform state
12. Start and enable all three services

**Run the role:**
```bash
export HCLOUD_TOKEN=<your-token>
ansible-playbook -i ansible/inventory.ini ansible/site.yml --tags autoscaler
```

---

## 8. join-worker.yml

**Deployed to:** `/opt/infra/prometheus/ansible/join-worker.yml` on bastion  
**Called by:** `webhook.py` during scale-out

This playbook runs from the bastion (which is on the same private network as the workers).

**Steps:**
1. SSH to master → run `kubeadm token create --print-join-command`
2. SSH to new worker → install `kubeadm`, `kubelet`, `kubectl`, `prometheus-node-exporter`
3. Enable `prometheus-node-exporter` on the new worker
4. Run the join command on the new worker
5. Wait up to 4 minutes for the node to appear in `kubectl get node`
6. Label the node as `node-role.kubernetes.io/worker=worker`

---

## Testing

### Send a test alert manually

```bash
ssh -i ~/.ssh/jilani root@188.245.215.21 "
curl -s -X POST http://localhost:9093/api/v2/alerts \
  -H 'Content-Type: application/json' \
  -d '[{
    \"labels\": {
      \"alertname\": \"NodeDown\",
      \"severity\": \"critical\",
      \"team\": \"infra\",
      \"job\": \"k8s-nodes\",
      \"instance\": \"10.20.0.11:9100\",
      \"nodename\": \"hzn-k8s-worker-1-jilani\"
    },
    \"annotations\": {
      \"summary\": \"Node Unreachable — hzn-k8s-worker-1-jilani\",
      \"description\": \"Test alert — node_exporter not responding.\"
    },
    \"startsAt\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
  }]'
"
```

### Trigger scale-out manually

```bash
ssh -i ~/.ssh/jilani root@188.245.215.21 "
curl -s -X POST http://localhost:8080 \
  -H 'Content-Type: application/json' \
  -d '{\"alerts\": [{\"status\": \"firing\", \"labels\": {\"action\": \"scale-out\"}}]}'
"
```

### Check current targets

```bash
ssh -i ~/.ssh/jilani root@188.245.215.21 "cat /opt/infra/prometheus/config/targets.json"
```

### Check active alerts in Alertmanager

```bash
curl -s http://188.245.215.21:9093/api/v2/alerts | python3 -m json.tool
```

### Stop the autoscaler temporarily

```bash
ssh -i ~/.ssh/jilani root@188.245.215.21 "systemctl stop autoscaler"
# to restart:
ssh -i ~/.ssh/jilani root@188.245.215.21 "systemctl start autoscaler"
```

---

## Common Issues

| Symptom | Cause | Fix |
|---|---|---|
| `NodeDown` alert for a new node | Node added to targets before node_exporter started | `sync_loop` now health-checks before adding |
| `NodeDown` alert on scale-in | Node removed from cluster but still in targets | Scale-in removes from targets **before** draining |
| targets.json reset to stale data | Ansible playbook task "Generate initial targets.json" overwrites live data | Run Ansible only when needed; autoscaler restores correct state within 60s |
| Cooldown blocking scale | Last scale was < 10 min ago | Check `journalctl -fu autoscaler` for "Cooldown active" |
| Email shows raw label dump | Alertmanager using default HTML template | Custom `html:` field in `alertmanager.yml.j2` overrides it |
