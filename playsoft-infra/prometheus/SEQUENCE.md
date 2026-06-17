# Sequence Diagram — Prometheus Autoscaling Pipeline

---

## Diagram 1 — Ansible Deployment (autoscaler role)

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'background': '#ffffff', 'mainBkg': '#ffffff', 'primaryColor': '#f0f0f0', 'primaryTextColor': '#000000', 'primaryBorderColor': '#333333', 'lineColor': '#333333', 'textColor': '#000000', 'actorTextColor': '#000000', 'actorBkg': '#f5f5f5', 'actorBorderColor': '#333333', 'actorLineColor': '#333333', 'signalColor': '#333333', 'signalTextColor': '#000000', 'noteTextColor': '#000000', 'noteBkgColor': '#ffffee', 'noteBorderColor': '#999933', 'loopTextColor': '#000000', 'activationBorderColor': '#333333', 'activationBkgColor': '#eeeeee', 'sequenceNumberColor': '#ffffff', 'labelBoxBkgColor': '#f5f5f5', 'labelBoxBorderColor': '#333333', 'labelTextColor': '#000000'}}}%%
sequenceDiagram
    autonumber
    participant Op as Operator<br/>(local machine)
    participant AC as Ansible Controller<br/>(localhost)
    participant Bastion as Bastion Host<br/>(188.x.x.x)
    participant TF as Terraform<br/>(on Bastion)
    participant HCLOUD as Hetzner Cloud API

    rect rgb(255, 255, 255)
        Op->>AC: export HCLOUD_TOKEN && ansible-playbook site.yml --tags autoscaler

        rect rgb(230, 240, 255)
            Note over AC,Bastion: Stage 1 — Validate & Install Packages
            AC->>AC: assert HCLOUD_TOKEN is set in local env
            AC->>Bastion: Add HashiCorp apt repo + GPG key
            AC->>Bastion: apt install prometheus, ansible, terraform, python3
            AC->>Bastion: Download & install alertmanager binary (v0.32.1)
            AC->>Bastion: Create /var/lib/alertmanager/
        end

        rect rgb(230, 255, 230)
            Note over AC,Bastion: Stage 2 — Token Security
            AC->>Bastion: mkdir /etc/autoscaler/ (mode 0700, root only)
            AC->>Bastion: Write HCLOUD_TOKEN → /etc/autoscaler/env (mode 0600)
            Note right of Bastion: Token never appears in ps<br/>or systemd unit files
        end

        rect rgb(255, 245, 220)
            Note over AC,TF: Stage 3 — Deploy Project Files
            AC->>Bastion: Create /opt/infra/prometheus/ directory tree
            AC->>Bastion: Copy webhook.py → webhook/
            AC->>Bastion: Copy prometheus.yml + alerts.yml → config/
            AC->>Bastion: Template alertmanager.yml.j2 → config/alertmanager.yml
            AC->>Bastion: Copy join-worker.yml → ansible/
            AC->>Bastion: rsync terraform/ → terraform/ (exclude .terraform)
            AC->>TF: terraform init -upgrade
            TF->>HCLOUD: validate provider credentials
            HCLOUD-->>TF: OK
        end

        rect rgb(255, 230, 230)
            Note over AC,Bastion: Stage 4 — Systemd Units
            AC->>Bastion: Install prometheus-override.conf → /etc/systemd/system/prometheus.service.d/
            AC->>Bastion: Install alertmanager.service → /etc/systemd/system/
            AC->>Bastion: Install autoscaler.service (EnvironmentFile=/etc/autoscaler/env)
            AC->>Bastion: systemctl daemon-reload
        end

        rect rgb(240, 230, 255)
            Note over AC,TF: Stage 5 — Generate Initial Targets & Start Services
            AC->>TF: terraform output -json worker_private_ips
            TF-->>AC: ["10.20.0.11", ...]
            AC->>Bastion: Write targets.json (master + current workers)
            AC->>Bastion: systemctl enable --now prometheus
            AC->>Bastion: systemctl enable --now alertmanager
            AC->>Bastion: systemctl enable --now autoscaler
            Bastion-->>Op: all services active
        end
    end
```

---

### Stage-by-stage Explanation — Deployment

| # | Description |
|---|---|
| 1 | Operator exports `HCLOUD_TOKEN` in their shell and runs the Ansible playbook targeting the `bastion` group with tag `autoscaler`. |
| 2 | Ansible asserts the token is present on the control node before touching the bastion — fails fast if missing. |
| 3 | HashiCorp apt repository and GPG key are added to the bastion so Terraform can be installed via apt. |
| 4 | Core packages installed: `prometheus` (apt), `ansible`, `terraform`, `python3`. |
| 5 | Alertmanager v0.32.1 binary is downloaded from GitHub releases and placed at `/usr/local/bin/alertmanager`. |
| 6 | Alertmanager storage directory created at `/var/lib/alertmanager/`. |
| 7 | `/etc/autoscaler/` directory created with mode `0700` — only root can enter it. |
| 8 | Token written to `/etc/autoscaler/env` with mode `0600`. Ansible uses `no_log: true` on this task so the value never appears in logs. |
| 9 | `/opt/infra/prometheus/` directory tree created with sub-dirs: `webhook/`, `config/`, `ansible/`, `terraform/`. |
| 10 | `webhook.py` copied to `webhook/`. |
| 11 | `prometheus.yml` and `alerts.yml` copied to `config/`. |
| 12 | `alertmanager.yml.j2` is rendered (Jinja2 → YAML) and written to `config/alertmanager.yml`. |
| 13 | `join-worker.yml` Ansible playbook copied to `ansible/`. |
| 14 | Terraform files synced from local machine to bastion with `rsync` (`.terraform/` excluded to avoid uploading provider binaries). |
| 15 | `terraform init -upgrade` runs on the bastion to download the Hetzner provider. |
| 16 | Terraform validates credentials against the Hetzner Cloud API. |
| 17 | Prometheus systemd override installed — points `--config.file` to `/opt/infra/prometheus/config/prometheus.yml` instead of the apt default. |
| 18 | `alertmanager.service` unit installed pointing to the project config directory. |
| 19 | `autoscaler.service` unit installed with `EnvironmentFile=/etc/autoscaler/env` — the token is injected at runtime, not baked in. |
| 20 | `systemctl daemon-reload` picks up all new unit files. |
| 21 | Ansible reads current worker IPs from Terraform output to generate an accurate initial `targets.json`. |
| 22 | Terraform returns the list of worker private IPs from state. |
| 23 | `targets.json` written with one entry per node (master + workers), each with a `nodename` label. |
| 24–26 | All three services are enabled and started. The `autoscaler` service immediately starts the background Hetzner discovery thread. |

---

## Diagram 2 — Scale-Out Pipeline (CPU Critical)

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'background': '#ffffff', 'mainBkg': '#ffffff', 'primaryColor': '#f0f0f0', 'primaryTextColor': '#000000', 'primaryBorderColor': '#333333', 'lineColor': '#333333', 'textColor': '#000000', 'actorTextColor': '#000000', 'actorBkg': '#f5f5f5', 'actorBorderColor': '#333333', 'actorLineColor': '#333333', 'signalColor': '#333333', 'signalTextColor': '#000000', 'noteTextColor': '#000000', 'noteBkgColor': '#ffffee', 'noteBorderColor': '#999933', 'loopTextColor': '#000000', 'activationBorderColor': '#333333', 'activationBkgColor': '#eeeeee', 'sequenceNumberColor': '#ffffff', 'labelBoxBkgColor': '#f5f5f5', 'labelBoxBorderColor': '#333333', 'labelTextColor': '#000000'}}}%%
sequenceDiagram
    autonumber
    participant Node as K8s Node<br/>(node_exporter :9100)
    participant Prom as Prometheus<br/>(:9090)
    participant Targets as targets.json
    participant AM as Alertmanager<br/>(:9093)
    participant WH as Autoscaler Webhook<br/>(:8080)
    participant TF as Terraform
    participant HCLOUD as Hetzner Cloud
    participant NewWorker as New Worker Node
    participant Master as K8s Master
    participant Email as Email Inbox

    rect rgb(255, 255, 255)

        rect rgb(230, 240, 255)
            Note over Node,Prom: Phase 1 — Detection
            Prom->>Targets: read targets.json (every 30s)
            Targets-->>Prom: [master:9100, worker-1:9100, ...]
            loop every 15s
                Prom->>Node: GET /metrics (scrape)
                Node-->>Prom: node_cpu_seconds_total{mode="idle"} ...
            end
            Note over Prom: CPU > 85% for 2 min<br/>→ NodeCPUCritical fires
            Prom->>AM: POST /api/v1/alerts<br/>[NodeCPUCritical, severity=critical, action=scale-out]
        end

        rect rgb(230, 255, 230)
            Note over AM,Email: Phase 2 — Alertmanager Routing
            AM->>AM: match route: severity=critical + action=scale-out
            AM->>WH: POST http://localhost:8080<br/>{"alerts": [{"status":"firing","labels":{"action":"scale-out"}}]}
            AM->>Email: send FIRING email (HTML template)
        end

        rect rgb(255, 245, 220)
            Note over WH,HCLOUD: Phase 3 — Terraform Provision
            WH->>WH: check cooldown (600s) — OK
            WH->>TF: terraform output -json worker_private_ips
            TF-->>WH: current count = N
            WH->>TF: terraform apply -var worker_count=N+1
            TF->>HCLOUD: POST /v1/servers (hzn-k8s-worker-N+1)
            HCLOUD-->>TF: server created, IP 10.20.0.(11+N)
            TF-->>WH: Apply complete — 1 added
        end

        rect rgb(255, 230, 230)
            Note over WH,NewWorker: Phase 4 — Wait for Node Ready
            loop every 5s (max 3 min)
                WH->>NewWorker: SSH echo ok
                NewWorker-->>WH: connection refused / ok
            end
            Note over WH,NewWorker: SSH up — wait for cloud-init
            loop every 5s (max 5 min)
                WH->>NewWorker: cloud-init status
                NewWorker-->>WH: running / done / SSH drops (reboot)
            end
            Note over WH,NewWorker: reboot detected
            loop every 5s (max 5 min)
                WH->>NewWorker: SSH echo ok
                NewWorker-->>WH: ok (back online)
            end
        end

        rect rgb(240, 230, 255)
            Note over WH,Master: Phase 5 — Join Cluster (Ansible)
            WH->>WH: write /tmp/join-inventory.ini
            WH->>Master: ansible → kubeadm token create
            Master-->>WH: kubeadm join 10.20.0.10:6443 --token ...
            WH->>NewWorker: ansible → apt install kubeadm kubelet kubectl
            WH->>NewWorker: ansible → apt install prometheus-node-exporter
            WH->>NewWorker: ansible → systemctl enable node_exporter
            WH->>NewWorker: ansible → kubeadm join (uses token from master)
            NewWorker->>Master: join cluster
            WH->>Master: ansible → kubectl get node (retry 24×, 10s delay)
            Master-->>WH: node Ready
            WH->>Master: ansible → kubectl label node worker
        end

        rect rgb(230, 255, 255)
            Note over WH,Prom: Phase 6 — Update Prometheus Targets
            WH->>Targets: write targets.json (add 10.20.0.(11+N):9100 with nodename label)
            Note over Prom: refresh_interval: 30s
            Prom->>Targets: re-read targets.json
            Targets-->>Prom: new node included
            Prom->>NewWorker: GET /metrics (first scrape)
            NewWorker-->>Prom: metrics OK
            Note over Prom: up{nodename="<WORKER_NODE_NAME_N>"} = 1
        end

    end
```

---

### Phase-by-phase Explanation — Scale-Out

| # | Description |
|---|---|
| 1 | Prometheus re-reads `targets.json` every 30 seconds to discover the current list of nodes to scrape. |
| 2 | `targets.json` returns one entry per node, each with a `nodename` label for human-readable alerts. |
| 3–4 | Every 15 seconds Prometheus scrapes `node_exporter` on each node and stores CPU metrics. |
| 5 | After CPU stays above 85% for 2 consecutive minutes, the `NodeCPUCritical` alert transitions to **firing**. |
| 6 | Prometheus pushes the alert to Alertmanager via its internal API. |
| 7 | Alertmanager matches the alert against the route `severity=critical + action=scale-out` and selects the `autoscaler` receiver. |
| 8 | Alertmanager sends an HTTP POST to the autoscaler webhook on `localhost:8080`. |
| 9 | Alertmanager also sends a FIRING email to the operator using the HTML template. |
| 10 | The webhook checks the 600-second cooldown — rejects if a scale happened within the last 10 minutes. |
| 11–12 | `terraform output` reads the current worker count from Terraform state. |
| 13 | `terraform apply -var worker_count=N+1` is run — Terraform calculates the diff and creates one new server. |
| 14 | Hetzner Cloud provisions the new server with a deterministic private IP (`10.20.0.11`, `.12`, etc.). |
| 15 | Terraform reports success. |
| 16–17 | The webhook polls SSH on the new IP every 5 seconds until it responds (the server needs ~30s to boot). |
| 18–19 | `cloud-init status` is polled — when SSH drops it means a reboot was triggered by cloud-init's final step. |
| 20–21 | After the reboot, SSH is polled again until the node comes back. |
| 22 | A temporary Ansible inventory file is written to `/tmp/join-inventory.ini` with the master and new worker. |
| 23–24 | Ansible connects to the master and runs `kubeadm token create` to get a fresh join command. |
| 25–27 | On the new worker: `kubeadm`, `kubelet`, `kubectl`, and `prometheus-node-exporter` are installed and `node_exporter` is enabled. |
| 28–29 | The worker runs `kubeadm join` and connects to the master control plane. |
| 30–31 | Ansible waits up to 4 minutes (24 retries × 10s) for `kubectl get node` to succeed. |
| 32 | The node is labelled `node-role.kubernetes.io/worker=worker`. |
| 33 | `webhook.py` updates `targets.json` adding the new node's IP and `nodename` label. |
| 34–36 | Within 30 seconds Prometheus re-reads `targets.json`, discovers the new target, and begins scraping it. |

---

## Diagram 3 — Scale-In Pipeline (Low CPU)

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'background': '#ffffff', 'mainBkg': '#ffffff', 'primaryColor': '#f0f0f0', 'primaryTextColor': '#000000', 'primaryBorderColor': '#333333', 'lineColor': '#333333', 'textColor': '#000000', 'actorTextColor': '#000000', 'actorBkg': '#f5f5f5', 'actorBorderColor': '#333333', 'actorLineColor': '#333333', 'signalColor': '#333333', 'signalTextColor': '#000000', 'noteTextColor': '#000000', 'noteBkgColor': '#ffffee', 'noteBorderColor': '#999933', 'loopTextColor': '#000000', 'activationBorderColor': '#333333', 'activationBkgColor': '#eeeeee', 'sequenceNumberColor': '#ffffff', 'labelBoxBkgColor': '#f5f5f5', 'labelBoxBorderColor': '#333333', 'labelTextColor': '#000000'}}}%%
sequenceDiagram
    autonumber
    participant Prom as Prometheus<br/>(:9090)
    participant AM as Alertmanager<br/>(:9093)
    participant WH as Autoscaler Webhook<br/>(:8080)
    participant Targets as targets.json
    participant Master as K8s Master
    participant Worker as Worker to Remove
    participant TF as Terraform
    participant HCLOUD as Hetzner Cloud
    participant Email as Email Inbox

    rect rgb(255, 255, 255)

        rect rgb(230, 240, 255)
            Note over Prom,AM: Phase 1 — Detection
            Note over Prom: avg cluster CPU < 20%<br/>for 10 consecutive minutes<br/>→ NodeCPULow fires
            Prom->>AM: POST /api/v1/alerts<br/>[NodeCPULow, severity=info, action=scale-in]
        end

        rect rgb(230, 255, 230)
            Note over AM,Email: Phase 2 — Routing
            AM->>AM: match route: action=scale-in
            AM->>WH: POST http://localhost:8080
            AM->>Email: send FIRING email
        end

        rect rgb(255, 245, 220)
            Note over WH,Targets: Phase 3 — Pre-Drain Safety (targets first)
            WH->>TF: terraform output -json worker_private_ips
            TF-->>WH: current count = N (N ≥ 2, else abort)
            WH->>Targets: write targets.json with worker_count = N-1
            Note right of Targets: IP removed BEFORE drain<br/>→ NodeDown alert never fires
            Note over Prom: picks up change within 30s<br/>stops scraping removed IP
        end

        rect rgb(255, 230, 230)
            Note over WH,Master: Phase 4 — Drain & Delete Node
            WH->>Master: SSH → kubectl drain <node> --ignore-daemonsets --delete-emptydir-data --force
            Master->>Master: evict all pods from node
            Master-->>WH: drain complete
            WH->>Master: SSH → kubectl delete node <node>
            Master-->>WH: node deleted from cluster
        end

        rect rgb(240, 230, 255)
            Note over WH,HCLOUD: Phase 5 — Terraform Destroy
            WH->>TF: terraform apply -var worker_count=N-1
            TF->>HCLOUD: DELETE /v1/servers/<id>
            HCLOUD-->>TF: server deleted
            TF-->>WH: Apply complete — 1 destroyed
        end

        rect rgb(230, 255, 255)
            Note over AM,Email: Phase 6 — Resolution
            Note over AM: resolve_timeout: 5m<br/>NodeCPULow resolves
            AM->>Email: send RESOLVED email (green card)
        end

    end
```

---

### Phase-by-phase Explanation — Scale-In

| # | Description |
|---|---|
| 1 | Prometheus evaluates the cluster-wide average CPU across all `k8s-nodes` targets. When it stays below 20% for 10 consecutive minutes, `NodeCPULow` fires. |
| 2 | The alert is pushed to Alertmanager. |
| 3 | Alertmanager matches the route `action=scale-in` and sends to the `autoscaler` webhook (repeat interval: 20 minutes). |
| 4 | A FIRING email is sent to the operator. |
| 5–6 | The webhook reads current worker count from Terraform state. If count ≤ 1, the scale-in is aborted — the cluster always keeps at least 1 worker. |
| 7 | **Critical safety step:** the worker's IP is removed from `targets.json` *before* the node is drained. This prevents Prometheus from firing `NodeDown` while the drain is in progress. |
| 8 | Within 30 seconds Prometheus stops scraping the removed IP. |
| 9 | `kubectl drain` gracefully evicts all user pods from the target node. DaemonSet pods and local-storage pods are force-removed. |
| 10 | Drain completes successfully. If drain fails, the webhook rolls back by re-adding the IP to `targets.json` and returns `False`. |
| 11 | `kubectl delete node` removes the node object from the Kubernetes API server. |
| 12 | `terraform apply -var worker_count=N-1` is run — Terraform destroys the last worker VM. |
| 13 | Hetzner Cloud deletes the server. |
| 14 | Terraform reports the destroy is complete. |
| 15 | After `resolve_timeout: 5m`, Alertmanager marks `NodeCPULow` as resolved and sends a green RESOLVED email. |

---

## Diagram 4 — Background Node Discovery (sync_loop)

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'background': '#ffffff', 'mainBkg': '#ffffff', 'primaryColor': '#f0f0f0', 'primaryTextColor': '#000000', 'primaryBorderColor': '#333333', 'lineColor': '#333333', 'textColor': '#000000', 'actorTextColor': '#000000', 'actorBkg': '#f5f5f5', 'actorBorderColor': '#333333', 'actorLineColor': '#333333', 'signalColor': '#333333', 'signalTextColor': '#000000', 'noteTextColor': '#000000', 'noteBkgColor': '#ffffee', 'noteBorderColor': '#999933', 'loopTextColor': '#000000', 'activationBorderColor': '#333333', 'activationBkgColor': '#eeeeee', 'sequenceNumberColor': '#ffffff', 'labelBoxBkgColor': '#f5f5f5', 'labelBoxBorderColor': '#333333', 'labelTextColor': '#000000'}}}%%
sequenceDiagram
    autonumber
    participant WH as Autoscaler sync_loop<br/>(background thread)
    participant HCLOUD as Hetzner Cloud API
    participant Targets as targets.json
    participant NE as node_exporter<br/>(new node :9100)
    participant Prom as Prometheus

    rect rgb(255, 255, 255)

        Note over WH: autoscaler starts → thread launched
        WH->>HCLOUD: GET /v1/servers (startup sync)
        HCLOUD-->>WH: full server list
        WH->>Targets: write initial targets.json

        loop every 60 seconds
            WH->>HCLOUD: GET /v1/servers?per_page=50
            HCLOUD-->>WH: [{name, private_ip}, ...]

            WH->>Targets: read current targets.json
            Targets-->>WH: current IP → nodename map

            alt server in Hetzner AND already in targets
                Note over WH: keep — even if node_exporter is down<br/>(Prometheus fires NodeDown if truly unreachable)
            else server in Hetzner AND NOT in targets (new server)
                WH->>NE: GET http://ip:9100/metrics (health check, 3s timeout)
                alt node_exporter UP
                    NE-->>WH: 200 OK
                    WH->>Targets: add new entry to targets.json
                else node_exporter DOWN (still booting)
                    NE-->>WH: timeout / connection refused
                    Note over WH: skip — retry next cycle
                end
            else server NOT in Hetzner (deleted)
                WH->>Targets: remove entry from targets.json
            end

            alt targets.json changed
                WH->>Targets: write updated targets.json
                Note over Prom: picks up change within 30s<br/>(file_sd refresh_interval)
            end
        end
    end
```

---

### Step-by-step Explanation — sync_loop

| # | Description |
|---|---|
| 1 | At startup, the webhook immediately calls the Hetzner API and writes an accurate initial `targets.json` before the HTTP server starts. |
| 2–3 | Full server list returned and written to `targets.json`. |
| 4 | Every 60 seconds the background thread wakes and calls the Hetzner API. |
| 5 | Returns all servers with their name and private IP. |
| 6–7 | The current `targets.json` is read to build a map of IP → nodename currently being scraped. |
| 8 | **Keep rule:** if the server exists in Hetzner and is already in targets, it stays — even if `node_exporter` is temporarily down. Prometheus handles that case by firing `NodeDown`. |
| 9 | **Add rule:** a new server (in Hetzner but not in targets) is only added after `node_exporter` successfully responds. This prevents `NodeDown` from firing for nodes that are still provisioning. |
| 10–11 | Health check passes — entry added to the merged targets map. |
| 12–13 | Health check fails (node still booting) — skipped, will be retried next cycle in 60 seconds. |
| 14 | **Remove rule:** a server that no longer exists on Hetzner is removed from targets. |
| 15–16 | If the merged targets differ from the current file, `targets.json` is overwritten and Prometheus picks up the change within 30 seconds. |

---

## Diagram 5 — Alert Email Flow (NodeDown)

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'background': '#ffffff', 'mainBkg': '#ffffff', 'primaryColor': '#f0f0f0', 'primaryTextColor': '#000000', 'primaryBorderColor': '#333333', 'lineColor': '#333333', 'textColor': '#000000', 'actorTextColor': '#000000', 'actorBkg': '#f5f5f5', 'actorBorderColor': '#333333', 'actorLineColor': '#333333', 'signalColor': '#333333', 'signalTextColor': '#000000', 'noteTextColor': '#000000', 'noteBkgColor': '#ffffee', 'noteBorderColor': '#999933', 'loopTextColor': '#000000', 'activationBorderColor': '#333333', 'activationBkgColor': '#eeeeee', 'sequenceNumberColor': '#ffffff', 'labelBoxBkgColor': '#f5f5f5', 'labelBoxBorderColor': '#333333', 'labelTextColor': '#000000'}}}%%
sequenceDiagram
    autonumber
    participant Node as K8s Node<br/>(node_exporter)
    participant Prom as Prometheus
    participant AM as Alertmanager<br/>(:9093)
    participant SMTP as Gmail SMTP<br/>(:587 TLS)
    participant Email as Operator Email

    rect rgb(255, 255, 255)

        rect rgb(255, 230, 230)
            Note over Node,Prom: Node becomes unreachable
            loop every 15s scrape
                Prom->>Node: GET /metrics
                Node-->>Prom: timeout / connection refused
                Note over Prom: up{job="k8s-nodes", nodename="..."} = 0
            end
            Note over Prom: up == 0 for 1 minute<br/>→ NodeDown transitions to FIRING
            Prom->>AM: POST /api/v1/alerts [NodeDown, severity=critical]
        end

        rect rgb(255, 245, 220)
            Note over AM,SMTP: Alertmanager deduplicates and routes
            AM->>AM: group_wait: 30s (collect sibling alerts)
            AM->>AM: match default route → email receiver
            AM->>SMTP: STARTTLS connect
            SMTP-->>AM: TLS handshake OK
            AM->>SMTP: AUTH LOGIN (sender + app password)
            SMTP-->>AM: authenticated
            AM->>SMTP: MAIL FROM / RCPT TO / DATA
            Note over AM: Subject: [FIRING] Node Unreachable — <nodename><br/>Body: HTML card (red border, node table, description)
            SMTP-->>AM: message accepted
        end

        rect rgb(230, 255, 230)
            Note over SMTP,Email: Email delivered
            SMTP->>Email: deliver FIRING email
            Note over Email: 🚨 Red card<br/>Node, Severity, Fired at, Description
        end

        rect rgb(230, 240, 255)
            Note over Node,AM: Node recovers
            Node->>Prom: GET /metrics → 200 OK
            Note over Prom: up == 1 → alert resolves
            Note over AM: resolve_timeout: 5m elapses<br/>status → resolved
            AM->>SMTP: send RESOLVED email
            SMTP->>Email: deliver RESOLVED email
            Note over Email: ✅ Green card<br/>Node, Severity, Fired at, Resolved at
        end

    end
```

---

### Step-by-step Explanation — Alert Email

| # | Description |
|---|---|
| 1–3 | Every 15 seconds Prometheus scrapes all targets. When a node's `node_exporter` stops responding, `up` drops to `0`. |
| 4 | After 1 full minute of `up == 0`, the `NodeDown` alert transitions from **pending** to **firing** and is pushed to Alertmanager. |
| 5 | Alertmanager waits `group_wait: 30s` to collect any other alerts that fire at the same time before sending one grouped email. |
| 6 | The alert matches the default route (no `action` label) → routed to the `default` receiver (email). |
| 7–9 | Alertmanager connects to Gmail SMTP on port 587 using STARTTLS and authenticates with the app password from the config. |
| 10 | The email is composed: subject uses `[FIRING] + summary annotation`, body uses the custom HTML template with a **red** left-border card. |
| 11–12 | SMTP accepts the message and delivers it to the operator's inbox. |
| 13–14 | Once the node recovers, `node_exporter` starts responding and `up` returns to `1`. The alert transitions back to **resolved**. |
| 15 | After `resolve_timeout: 5m`, Alertmanager marks the alert resolved and sends a second email. |
| 16–17 | The RESOLVED email is delivered — same HTML template but with a **green** border and a "Resolved at" row in the table. |

---

## Alert Rules Summary

| Alert | Expression | For | Labels | Email | Webhook |
|---|---|---|---|---|---|
| `NodeCPUWarning` | CPU > 70% | 2m | severity=warning | ✅ | ❌ |
| `NodeCPUCritical` | CPU > 85% | 2m | severity=critical, **action=scale-out** | ✅ | ✅ scale-out |
| `NodeCPULow` | avg cluster CPU < 20% | 10m | severity=info, **action=scale-in** | ✅ | ✅ scale-in |
| `NodeDown` | up == 0 | 1m | severity=critical | ✅ | ❌ |
| `NodeMemoryWarning` | RAM > 80% | 2m | severity=warning | ✅ | ❌ |
| `NodeMemoryCritical` | RAM > 90% | 2m | severity=critical | ✅ | ❌ |
| `NodeDiskWarning` | disk `/` > 75% | 5m | severity=warning | ✅ | ❌ |
| `NodeDiskCritical` | disk `/` > 90% | 5m | severity=critical | ✅ | ❌ |
