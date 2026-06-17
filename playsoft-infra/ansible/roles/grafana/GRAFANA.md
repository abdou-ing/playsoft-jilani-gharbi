# Grafana — How It Works

## What is Grafana

Grafana is a visualization tool. It does **not** collect or store metrics — it only reads them.
Prometheus collects and stores metrics. Grafana connects to Prometheus and draws graphs from it.

```
node_exporter          Prometheus              Grafana
(on each node)  ──►   (on bastion)    ◄──     (on bastion)
port 9100              port 9090               port 3000
  scrapes                stores                 reads & draws
```

---

## Architecture in This Setup

```
┌─────────────────────────────────────────────────────┐
│                    Bastion                          │
│                                                     │
│  ┌─────────────┐    query     ┌──────────────────┐  │
│  │  Prometheus │ ◄──────────  │     Grafana      │  │
│  │   :9090     │  PromQL      │     :3000        │  │
│  └──────┬──────┘              └──────────────────┘  │
│         │ scrape :9100                               │
└─────────┼───────────────────────────────────────────┘
          │ (private network 10.20.0.0/24)
    ┌─────▼──────────────────────────────┐
    │  master-1   master-2               │
    │  worker-1   worker-2   worker-N    │
    │  (node_exporter on each)           │
    └────────────────────────────────────┘
```

---

## How Grafana Gets Its Data

### Step 1 — Datasource

A datasource tells Grafana where to read metrics from.
In this setup it is configured automatically via provisioning:

**File:** `files/grafana-datasource.yml`
```yaml
datasources:
  - name: Prometheus
    type: prometheus
    url: http://localhost:9090   # Grafana calls Prometheus on the same server
    isDefault: true
```

When Grafana starts, it reads this file and registers Prometheus as its data source.
No manual clicks needed.

### Step 2 — Dashboards

A dashboard is a collection of panels (graphs, gauges, tables).
Each panel runs a PromQL query against Prometheus and draws the result.

Example: the CPU panel runs this query behind the scenes:
```promql
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100)
```
Grafana sends this to Prometheus every 30s and updates the graph.

### Step 3 — Dashboard Provisioning

Instead of importing dashboards manually every time, the Ansible role:

1. Puts a provider config in `/etc/grafana/provisioning/dashboards/provider.yml`
   — tells Grafana to load JSON files from `/var/lib/grafana/dashboards/`

2. Downloads the Node Exporter Full dashboard JSON (ID 1860) from grafana.com,
   renames it to **k8s-guacamole** (`uid: k8s-guacamole`, tags: `cluster`,
   `guacamole`, `masters`, `workers`), and saves it to
   `/var/lib/grafana/dashboards/k8s-guacamole.json`

Grafana picks it up on start automatically. Every 30 seconds it re-checks that
folder — so any new JSON file you drop there appears in Grafana without restart.

---

## k8s-guacamole Dashboard (based on Node Exporter Full, ID 1860)

This is the most popular node_exporter dashboard (5M+ downloads), re-tagged for
this cluster. It shows for each node:

| Panel | What it shows |
|---|---|
| CPU Usage | % per core, idle vs busy over time |
| Load Average | 1m / 5m / 15m system load |
| Memory Usage | RAM used / available / cached |
| Disk I/O | Read / write bytes per second |
| Disk Space | Used % per filesystem |
| Network Traffic | Bytes in / out per interface |
| System Uptime | How long since last reboot |

At the top there is a **node selector** — you can switch between master-1, master-2,
worker-1, worker-2 with a dropdown. All panels update instantly.

---

## How to Access

Grafana has no public access — it only listens on `localhost:3000` on the bastion.
Access it via SSH tunnel from your local machine:

```powershell
# Windows PowerShell
ssh -i "C:\Users\Jilani Gharbi\.ssh\jilani" `
    -L 3000:localhost:3000 `
    root@178.105.79.31 -N
```

Then open `http://localhost:3000` in your browser.

**First login:**
- Username: `admin`
- Password: `admin`
- Grafana will force you to change the password immediately.

---

## File Locations on Bastion

| File | Purpose |
|---|---|
| `/etc/grafana/grafana.ini` | Main Grafana config (port, auth, etc.) |
| `/etc/grafana/provisioning/datasources/prometheus.yml` | Auto-registers Prometheus |
| `/etc/grafana/provisioning/dashboards/provider.yml` | Points to dashboard folder |
| `/var/lib/grafana/dashboards/k8s-guacamole.json` | k8s-guacamole dashboard (cluster/guacamole/masters/workers) |
| `/var/lib/grafana/grafana.db` | SQLite database (users, saved dashboards) |

---

## How to Add More Dashboards

**Option A — From grafana.com (easiest):**
1. Go to grafana.com/grafana/dashboards
2. Find a dashboard, copy its ID (e.g. `3662` for Kubernetes)
3. In Grafana UI: Dashboards → Import → paste the ID → Load

**Option B — Via Ansible (permanent, survives redeploy):**
Add a task to the grafana role:
```yaml
- name: Download Kubernetes dashboard
  ansible.builtin.get_url:
    url: https://grafana.com/api/dashboards/3662/revisions/latest/download
    dest: /var/lib/grafana/dashboards/kubernetes.json
    owner: grafana
    group: grafana
    mode: '0644'
```

---

## Grafana vs Alertmanager

Both can send alerts but they serve different purposes here:

| | Grafana | Alertmanager |
|---|---|---|
| Source of alerts | Grafana queries | Prometheus rules |
| Used for | Visual exploration | Automated actions |
| Email alerts | Optional (not configured) | Yes — configured |
| Scale-out trigger | No | Yes — triggers webhook.py |

In this setup **Alertmanager handles all alerts**. Grafana is used only for visualization.

---

## Service Management on Bastion

```bash
# Check status
systemctl status grafana-server

# Restart
systemctl restart grafana-server

# Logs
journalctl -fu grafana-server
```
