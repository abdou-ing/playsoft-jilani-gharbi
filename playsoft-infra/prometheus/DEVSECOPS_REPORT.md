# Cloud DevSecOps Report — Prometheus Autoscaling Pipeline

> **Project:** Kubernetes Auto-Scaling on Hetzner Cloud
> **Stack:** Prometheus · Alertmanager · Python Webhook · Terraform · Ansible
> **Scope:** Monitoring, alerting, automated horizontal scaling, secret management
> **Skill applied:** `mermaid-devsecops` — see `skills/mermaid-devsecops/SKILL.md`

---

## Table of Contents

1. [C4 Architecture](#1-c4-architecture)
2. [Network Security Zones](#2-network-security-zones)
3. [Secret Management Flow](#3-secret-management-flow)
4. [Alert Decision Tree](#4-alert-decision-tree)
5. [Security Controls Summary](#5-security-controls-summary)
6. [Risk Register](#6-risk-register)

---

## 1. C4 Architecture

### Level 1 — System Context

Who interacts with the system and what external dependencies exist.

```mermaid
%%{init: {'theme': 'neutral', 'themeVariables': {'background': '#ffffff', 'mainBkg': '#ffffff', 'primaryColor': '#ffffff', 'primaryTextColor': '#000000', 'primaryBorderColor': '#333333', 'lineColor': '#333333', 'textColor': '#000000', 'actorTextColor': '#000000', 'actorBkg': '#ffffff', 'actorBorderColor': '#333333', 'actorLineColor': '#333333', 'signalColor': '#333333', 'signalTextColor': '#000000', 'noteTextColor': '#000000', 'noteBkgColor': '#ffffee', 'noteBorderColor': '#999933', 'loopTextColor': '#000000', 'activationBorderColor': '#333333', 'activationBkgColor': '#ffffff', 'sequenceNumberColor': '#ffffff', 'labelBoxBkgColor': '#ffffff', 'labelBoxBorderColor': '#333333', 'labelTextColor': '#000000', 'clusterBkg': '#ffffff', 'clusterBorder': '#333333', 'edgeLabelBackground': '#ffffff'}}}%%
graph TB
    classDef user     fill:#08427b,color:#fff,stroke:#073b6f,font-weight:bold
    classDef service  fill:#1168bd,color:#fff,stroke:#0e5ca8,font-weight:bold
    classDef external fill:#7f8c8d,color:#fff,stroke:#616a6b

    OP["Operator\n────────────\nDevOps Engineer\nLocal machine"]:::user

    subgraph SYS ["Autoscaling Pipeline  [Software System]"]
        PIPE["Bastion Host\n────────────\nPrometheus · Alertmanager\nWebhook · Terraform · Ansible\nPublic IP"]:::service
    end

    HC["Hetzner Cloud\n────────────\nCloud Provider\nVMs · Private Network\nSnapshot Images\nHetzner API"]:::external

    GM["Gmail SMTP\n────────────\nsmtp.gmail.com:587\nTLS · App Password\nAlert delivery"]:::external

    K8S["Kubernetes Cluster\n────────────\nPrivate network only\n10.20.0.0/24\nMaster + Workers"]:::external

    OP   -->|"Deploys via Ansible\nMonitors via :9090 / :9093"| PIPE
    PIPE -->|"Provisions / destroys worker VMs\nvia Terraform — Bearer Token"| HC
    PIPE -->|"Sends FIRING / RESOLVED\nalert emails via STARTTLS"| GM
    PIPE -->|"Scrapes node_exporter :9100\nJoins workers via kubeadm\nDrains nodes via kubectl"| K8S
    HC   -->|"Hosts all compute resources"| K8S
    GM   -->|"Delivers email to operator inbox"| OP
```

---

### Level 2 — Container Diagram (Bastion Host)

Internal components and how they communicate.

```mermaid
%%{init: {'theme': 'neutral', 'themeVariables': {'background': '#ffffff', 'mainBkg': '#ffffff', 'primaryColor': '#ffffff', 'primaryTextColor': '#000000', 'primaryBorderColor': '#333333', 'lineColor': '#333333', 'textColor': '#000000', 'actorTextColor': '#000000', 'actorBkg': '#ffffff', 'actorBorderColor': '#333333', 'actorLineColor': '#333333', 'signalColor': '#333333', 'signalTextColor': '#000000', 'noteTextColor': '#000000', 'noteBkgColor': '#ffffee', 'noteBorderColor': '#999933', 'loopTextColor': '#000000', 'activationBorderColor': '#333333', 'activationBkgColor': '#ffffff', 'sequenceNumberColor': '#ffffff', 'labelBoxBkgColor': '#ffffff', 'labelBoxBorderColor': '#333333', 'labelTextColor': '#000000', 'clusterBkg': '#ffffff', 'clusterBorder': '#333333', 'edgeLabelBackground': '#ffffff'}}}%%
graph LR
    classDef service  fill:#1168bd,color:#fff,stroke:#0e5ca8
    classDef config   fill:#f5a623,color:#000,stroke:#c8860c
    classDef secret   fill:#c0392b,color:#fff,stroke:#922b21
    classDef external fill:#7f8c8d,color:#fff,stroke:#616a6b

    subgraph BASTION ["Bastion Host — /opt/infra/prometheus/"]

        subgraph MON ["Monitoring Layer"]
            PROM["Prometheus\n:9090\n/usr/bin/prometheus"]:::service
            AM["Alertmanager\n:9093\n/usr/local/bin/alertmanager"]:::service
        end

        subgraph AUTO ["Automation Layer"]
            WH["Autoscaler Webhook\n:8080\nwebhook.py"]:::service
            TF["Terraform\n/opt/infra/prometheus/terraform/"]:::service
            ANS["Ansible\njoin-worker.yml"]:::service
        end

        subgraph CFG ["Config Files"]
            TARGETS["targets.json\ndynamic node list"]:::config
            ALCFG["alertmanager.yml\nroutes + email"]:::config
            PRCFG["prometheus.yml\nscrape config"]:::config
            ALERTS["alerts.yml\n8 alert rules"]:::config
        end

        subgraph SEC ["Secret Store"]
            ENV["/etc/autoscaler/env\nmode 0600 — root only"]:::secret
        end
    end

    NE["node_exporter\n:9100\neach k8s node"]:::external
    HC["Hetzner Cloud API\napi.hetzner.cloud"]:::external
    SMTP["Gmail SMTP\nsmtp.gmail.com:587"]:::external
    MASTER["K8s Master\n10.20.0.10"]:::external

    PRCFG  -->|reads| PROM
    ALERTS -->|loads| PROM
    TARGETS-->|file_sd every 30s| PROM
    ALCFG  -->|reads| AM

    PROM -->|scrape :9100 every 15s| NE
    PROM -->|POST /api/v1/alerts| AM
    AM   -->|POST localhost:8080| WH
    AM   -->|STARTTLS auth| SMTP

    WH -->|writes| TARGETS
    WH -->|terraform apply| TF
    WH -->|ansible-playbook| ANS
    WH -->|reads token| ENV

    TF  -->|Bearer token| HC
    ANS -->|SSH kubeadm join| MASTER
```

---

## 2. Network Security Zones

```mermaid
%%{init: {'theme': 'neutral', 'themeVariables': {'background': '#ffffff', 'mainBkg': '#ffffff', 'primaryColor': '#ffffff', 'primaryTextColor': '#000000', 'primaryBorderColor': '#333333', 'lineColor': '#333333', 'textColor': '#000000', 'actorTextColor': '#000000', 'actorBkg': '#ffffff', 'actorBorderColor': '#333333', 'actorLineColor': '#333333', 'signalColor': '#333333', 'signalTextColor': '#000000', 'noteTextColor': '#000000', 'noteBkgColor': '#ffffee', 'noteBorderColor': '#999933', 'loopTextColor': '#000000', 'activationBorderColor': '#333333', 'activationBkgColor': '#ffffff', 'sequenceNumberColor': '#ffffff', 'labelBoxBkgColor': '#ffffff', 'labelBoxBorderColor': '#333333', 'labelTextColor': '#000000', 'clusterBkg': '#ffffff', 'clusterBorder': '#333333', 'edgeLabelBackground': '#ffffff'}}}%%
graph TB
    classDef internet fill:#e74c3c,color:#fff,stroke:#c0392b,font-weight:bold
    classDef dmz      fill:#e67e22,color:#fff,stroke:#ca6f1e,font-weight:bold
    classDef private  fill:#27ae60,color:#fff,stroke:#1e8449,font-weight:bold
    classDef extapi   fill:#8e44ad,color:#fff,stroke:#76359d,font-weight:bold
    classDef config   fill:#ecf0f1,color:#333,stroke:#bdc3c7

    subgraph INET ["ZONE 1 — Internet (Untrusted)"]
        OP["Operator\nLocal Machine\nDynamic IP"]:::internet
        SMTP["Gmail SMTP\nsmtp.gmail.com:587"]:::internet
    end

    subgraph DMZ ["ZONE 2 — DMZ (Bastion — Semi-Trusted)"]
        BASTION["Bastion Host\nPUBLIC_IP\n────────────────\nPrometheus  :9090\nAlertmanager :9093\nWebhook :8080 localhost only"]:::dmz
        FW["Firewall Rules\n────────────────\nIN  22   SSH key-only\nIN  9090 Prometheus UI\nIN  9093 Alertmanager UI\nDENY 8080 from internet\nOUT 443  Hetzner API\nOUT 587  SMTP"]:::config
    end

    subgraph PRIV ["ZONE 3 — Private Network (Trusted) 10.20.0.0/24"]
        MASTER["K8s Master\n10.20.0.10\n────────────\nkubeadm :6443\nnode_exporter :9100"]:::private
        W1["Worker 1\n10.20.0.11\n────────────\nnode_exporter :9100\nkubelet"]:::private
        WN["Worker N\n10.20.0.11+N\n────────────\nnode_exporter :9100\nkubelet"]:::private
    end

    subgraph EXTAPI ["ZONE 4 — External APIs (Trusted with Token)"]
        HC["Hetzner Cloud API\napi.hetzner.cloud:443\nHTTPS Bearer Token"]:::extapi
    end

    OP      -->|"SSH :22 key auth only"| BASTION
    OP      -->|"HTTP :9090 Prometheus UI"| BASTION
    OP      -->|"HTTP :9093 Alertmanager UI"| BASTION
    BASTION -->|"scrape :9100 private network"| MASTER
    BASTION -->|"scrape :9100 private network"| W1
    BASTION -->|"scrape :9100 private network"| WN
    BASTION -->|"SSH :22 kubeadm join / kubectl"| MASTER
    BASTION -->|"HTTPS :443 Bearer HCLOUD_TOKEN"| HC
    BASTION -->|"STARTTLS :587 App Password"| SMTP
    HC      -->|"provision / destroy VMs"| WN
    SMTP    -->|"alert email delivery"| OP
```

---

### Network Exposure Table

| Port | Service | Exposed To | Auth Method | Risk |
|---|---|---|---|---|
| `22` | SSH | Internet | SSH key pair only | Low |
| `9090` | Prometheus UI | Internet | None | Medium — no auth |
| `9093` | Alertmanager UI | Internet | None | Medium — no auth |
| `8080` | Autoscaler Webhook | **localhost only** | None (internal) | Low — not routable |
| `9100` | node_exporter | Private network only | None | Low — isolated |
| `6443` | Kubernetes API | Private network only | kubeadm token | Low — isolated |
| `443` | Hetzner Cloud API | Outbound only | Bearer token | Low |
| `587` | Gmail SMTP | Outbound only | App password TLS | Low |

> **Recommendation:** Add IP allowlist or reverse proxy with basic auth to restrict `:9090` and `:9093`.

---

## 3. Secret Management Flow

```mermaid
%%{init: {'theme': 'neutral', 'themeVariables': {'background': '#ffffff', 'mainBkg': '#ffffff', 'primaryColor': '#ffffff', 'primaryTextColor': '#000000', 'primaryBorderColor': '#333333', 'lineColor': '#333333', 'textColor': '#000000', 'actorTextColor': '#000000', 'actorBkg': '#ffffff', 'actorBorderColor': '#333333', 'actorLineColor': '#333333', 'signalColor': '#333333', 'signalTextColor': '#000000', 'noteTextColor': '#000000', 'noteBkgColor': '#ffffee', 'noteBorderColor': '#999933', 'loopTextColor': '#000000', 'activationBorderColor': '#333333', 'activationBkgColor': '#ffffff', 'sequenceNumberColor': '#ffffff', 'labelBoxBkgColor': '#ffffff', 'labelBoxBorderColor': '#333333', 'labelTextColor': '#000000', 'clusterBkg': '#ffffff', 'clusterBorder': '#333333', 'edgeLabelBackground': '#ffffff'}}}%%
sequenceDiagram
    autonumber
    participant Op as Operator<br/>(local shell)
    participant Env as Shell ENV<br/>(local memory)
    participant AC as Ansible Controller<br/>(no_log: true)
    participant FS as /etc/autoscaler/env<br/>(0600, root only)
    participant SD as systemd unit<br/>(EnvironmentFile)
    participant WH as webhook.py process<br/>(os.environ)
    participant TF as Terraform process<br/>(env var)
    participant HC as Hetzner Cloud API

    rect rgb(255, 245, 220)
        Note over Op,Env: Secret injection — operator side
        Op->>Env: export HCLOUD_TOKEN=token
        Note right of Env: Never written to disk<br/>Never committed to git<br/>Lives in shell memory only
    end

    rect rgb(255, 230, 230)
        Note over AC,FS: Ansible deployment — token persisted securely
        Op->>AC: ansible-playbook site.yml --tags autoscaler
        AC->>AC: lookup env HCLOUD_TOKEN — read from local env
        AC->>FS: copy dest=/etc/autoscaler/env<br/>mode=0600 owner=root no_log=true
        Note right of FS: Token written once<br/>File readable only by root<br/>Task output suppressed no_log
    end

    rect rgb(230, 255, 230)
        Note over SD,WH: Runtime — systemd injects token into process
        SD->>WH: systemd start autoscaler.service<br/>EnvironmentFile=/etc/autoscaler/env
        Note right of SD: Token injected into process env<br/>Not visible in ps aux<br/>Not in unit file ExecStart
        WH->>WH: os.environ.get HCLOUD_TOKEN
    end

    rect rgb(230, 240, 255)
        Note over WH,HC: Usage — token used only for API calls
        WH->>TF: subprocess terraform apply<br/>inherits env with token
        TF->>HC: GET/POST api.hetzner.cloud<br/>Authorization: Bearer token
        HC-->>TF: 200 OK
        WH->>HC: GET /v1/servers discovery<br/>Authorization: Bearer token
        HC-->>WH: server list
    end

    rect rgb(240, 230, 255)
        Note over Op,HC: Gmail App Password — separate secret
        Note over AC,FS: auth_password stored in alertmanager.yml<br/>templated from alertmanager.yml.j2<br/>Not yet in a secret store
        Note over Op: Recommendation: move to Ansible Vault or env var
    end
```

---

### Secret Inventory

| Secret | Storage | Transit | At Rest | Rotation |
|---|---|---|---|---|
| `HCLOUD_TOKEN` | `/etc/autoscaler/env` (0600) | Shell env → Ansible (no_log) | 0600, root only | Manual on Hetzner dashboard |
| `GMAIL_APP_PASSWORD` | `alertmanager.yml` (plaintext) | Ansible template | World-readable config | Manual on Google account |
| SSH Private Key | `/root/.ssh/<SSH_KEY_NAME>` | Not transmitted | File system | Manual |
| `kubeadm join token` | Memory only | SSH channel | Never persisted | Auto-expires 24h |

### Secret Security Levels

```mermaid
%%{init: {'theme': 'neutral', 'themeVariables': {'background': '#ffffff', 'mainBkg': '#ffffff', 'primaryColor': '#ffffff', 'primaryTextColor': '#000000', 'primaryBorderColor': '#333333', 'lineColor': '#333333', 'textColor': '#000000', 'actorTextColor': '#000000', 'actorBkg': '#ffffff', 'actorBorderColor': '#333333', 'actorLineColor': '#333333', 'signalColor': '#333333', 'signalTextColor': '#000000', 'noteTextColor': '#000000', 'noteBkgColor': '#ffffee', 'noteBorderColor': '#999933', 'loopTextColor': '#000000', 'activationBorderColor': '#333333', 'activationBkgColor': '#ffffff', 'sequenceNumberColor': '#ffffff', 'labelBoxBkgColor': '#ffffff', 'labelBoxBorderColor': '#333333', 'labelTextColor': '#000000', 'clusterBkg': '#ffffff', 'clusterBorder': '#333333', 'edgeLabelBackground': '#ffffff'}}}%%
graph LR
    classDef ok   fill:#27ae60,color:#fff,stroke:#1e8449
    classDef warn fill:#f39c12,color:#000,stroke:#ca8a04
    classDef crit fill:#e74c3c,color:#fff,stroke:#c0392b

    T1["HCLOUD_TOKEN\nno_log · 0600 · EnvironmentFile\nNot in git · Not in ps"]:::ok
    T2["Gmail App Password\nPlaintext in alertmanager.yml\nNot in git · World-readable config"]:::warn
    T3["SSH Key\nFile system · Not transmitted\nKey-based auth only"]:::ok
    T4["kubeadm token\nAuto-generated · 24h TTL\nNever stored"]:::ok
```

---

## 4. Alert Decision Tree

```mermaid
%%{init: {'theme': 'neutral', 'themeVariables': {'background': '#ffffff', 'mainBkg': '#ffffff', 'primaryColor': '#ffffff', 'primaryTextColor': '#000000', 'primaryBorderColor': '#333333', 'lineColor': '#333333', 'textColor': '#000000', 'actorTextColor': '#000000', 'actorBkg': '#ffffff', 'actorBorderColor': '#333333', 'actorLineColor': '#333333', 'signalColor': '#333333', 'signalTextColor': '#000000', 'noteTextColor': '#000000', 'noteBkgColor': '#ffffee', 'noteBorderColor': '#999933', 'loopTextColor': '#000000', 'activationBorderColor': '#333333', 'activationBkgColor': '#ffffff', 'sequenceNumberColor': '#ffffff', 'labelBoxBkgColor': '#ffffff', 'labelBoxBorderColor': '#333333', 'labelTextColor': '#000000', 'clusterBkg': '#ffffff', 'clusterBorder': '#333333', 'edgeLabelBackground': '#ffffff'}}}%%
flowchart TD
    classDef trigger fill:#2c3e50,color:#fff,stroke:#1a252f,font-weight:bold
    classDef eval    fill:#2980b9,color:#fff,stroke:#1f618d
    classDef ok      fill:#27ae60,color:#fff,stroke:#1e8449
    classDef warn    fill:#f39c12,color:#000,stroke:#ca8a04
    classDef crit    fill:#e74c3c,color:#fff,stroke:#c0392b
    classDef infra   fill:#8e44ad,color:#fff,stroke:#76359d
    classDef skip    fill:#95a5a6,color:#fff,stroke:#717d7e

    START(["Prometheus\nevaluates rules\nevery 15s"]):::trigger

    START --> CPU_CHECK{"CPU usage ?"}:::eval
    START --> UP_CHECK{"node_exporter up ?"}:::eval
    START --> MEM_CHECK{"Memory usage ?"}:::eval
    START --> DISK_CHECK{"Disk / usage ?"}:::eval

    CPU_CHECK  -->|"above 85% for 2min"| CRIT_CPU["NodeCPUCritical\nseverity=critical\naction=scale-out"]:::crit
    CPU_CHECK  -->|"above 70% for 2min"| WARN_CPU["NodeCPUWarning\nseverity=warning"]:::warn
    CPU_CHECK  -->|"avg cluster below 20%\nfor 10min"| LOW_CPU["NodeCPULow\nseverity=info\naction=scale-in"]:::eval
    UP_CHECK   -->|"up==0 for 1min"| NODE_DOWN["NodeDown\nseverity=critical"]:::crit
    MEM_CHECK  -->|"above 90% for 2min"| CRIT_MEM["NodeMemoryCritical\nseverity=critical"]:::crit
    MEM_CHECK  -->|"above 80% for 2min"| WARN_MEM["NodeMemoryWarning\nseverity=warning"]:::warn
    DISK_CHECK -->|"above 90% for 5min"| CRIT_DISK["NodeDiskCritical\nseverity=critical"]:::crit
    DISK_CHECK -->|"above 75% for 5min"| WARN_DISK["NodeDiskWarning\nseverity=warning"]:::warn

    CRIT_CPU --> AM_ROUTE{"Alertmanager routing"}:::eval
    LOW_CPU  --> AM_ROUTE

    WARN_CPU  --> AM_EMAIL["Email only\nFIRING warning"]:::infra
    NODE_DOWN --> AM_EMAIL
    CRIT_MEM  --> AM_EMAIL
    WARN_MEM  --> AM_EMAIL
    CRIT_DISK --> AM_EMAIL
    WARN_DISK --> AM_EMAIL

    AM_ROUTE -->|"severity=critical\naction=scale-out"| CD_OUT{"Cooldown\n600s elapsed ?"}:::eval
    AM_ROUTE -->|"action=scale-in"| CD_IN{"Cooldown\n600s elapsed ?"}:::eval

    CD_OUT -->|"NO"| SK_OUT["Skip\ncooldown active"]:::skip
    CD_OUT -->|"YES"| SCALEOUT["SCALE-OUT\nTerraform +1 worker\nAnsible join\ntargets.json update\nrepeat 15m"]:::ok

    CD_IN -->|"NO"| SK_IN["Skip\ncooldown active"]:::skip
    CD_IN -->|"YES"| MIN_CHECK{"workers >= 2 ?"}:::eval

    MIN_CHECK -->|"NO — already 1"| SK_MIN["Skip\nminimum reached"]:::skip
    MIN_CHECK -->|"YES"| SCALEIN["SCALE-IN\nRemove from targets\nkubectl drain\nkubectl delete\nTerraform -1 worker\nrepeat 20m"]:::ok

    SCALEOUT --> EM_OUT["Email FIRING\nCPU Saturation\nScale-Out Triggered"]:::infra
    SCALEIN  --> EM_IN["Email FIRING\nLow Cluster CPU\nScale-In Triggered"]:::infra

    EM_OUT   --> RESOLVE["resolve_timeout 5m\nalert resolves"]:::eval
    EM_IN    --> RESOLVE
    AM_EMAIL --> RESOLVE
    RESOLVE  --> EM_RES["Email RESOLVED\ngreen card"]:::infra
```

---

### Alert Routing Summary

| Alert | Severity | Webhook | Email | Repeat Interval |
|---|---|---|---|---|
| `NodeCPUCritical` | critical | scale-out | yes | 15m |
| `NodeCPULow` | info | scale-in | yes | 20m |
| `NodeCPUWarning` | warning | no | yes | 15m |
| `NodeDown` | critical | no | yes | 15m |
| `NodeMemoryCritical` | critical | no | yes | 15m |
| `NodeMemoryWarning` | warning | no | yes | 15m |
| `NodeDiskCritical` | critical | no | yes | 15m |
| `NodeDiskWarning` | warning | no | yes | 15m |

---

## 5. Security Controls Summary

| Control | Status | Detail |
|---|---|---|
| **Secret at rest** | ✅ | `HCLOUD_TOKEN` in `/etc/autoscaler/env` mode 0600, root only |
| **Secret in transit** | ✅ | Ansible `no_log: true`, never in stdout/logs |
| **Secret in process** | ✅ | `EnvironmentFile` — not in `ExecStart`, not in `ps aux` |
| **Secret in git** | ✅ | Token never committed — read from local `export` at deploy time |
| **SSH authentication** | ✅ | Key-pair only, no password auth |
| **API communication** | ✅ | Hetzner API over HTTPS, Gmail over STARTTLS |
| **Network isolation** | ✅ | Workers on private network `10.20.0.0/24`, no public IP |
| **kubeadm token TTL** | ✅ | Auto-generated per join, expires 24h |
| **Webhook exposure** | ✅ | Webhook `:8080` bound to `localhost` only |
| **Prometheus/AM UI auth** | ⚠️ | No authentication — exposed on public IP |
| **Gmail password storage** | ⚠️ | Plaintext in `alertmanager.yml` — not yet in Ansible Vault |
| **Token rotation** | ⚠️ | No automated rotation — manual process on Hetzner dashboard |
| **Audit logging** | ⚠️ | `journalctl` only — no centralized log shipping |
| **RBAC on kubectl** | ❌ | Webhook uses `root` SSH + full `kubectl` — no scoped ServiceAccount |

---

## 6. Risk Register

| ID | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R1 | `HCLOUD_TOKEN` leaked via git | Low | Critical | Token not in repo; `no_log: true` in Ansible |
| R2 | Gmail app password exposed in config | Medium | High | Move to Ansible Vault or env var |
| R3 | Prometheus/Alertmanager UI open to internet | Medium | Medium | Add IP allowlist or reverse proxy with basic auth |
| R4 | Runaway scale-out — billing risk | Low | High | 600s cooldown between operations |
| R5 | False NodeDown on provisioning | Low | Medium | Health-check guard in `sync_loop` before adding to targets |
| R6 | Scale-in removes wrong node | Low | High | Always removes last IP `WORKER_BASE_IP + count - 1` |
| R7 | Ansible overwrites live `targets.json` | Medium | Medium | `sync_loop` reconciles within 60s after playbook run |
| R8 | SSH key compromise on bastion | Low | Critical | Key not in repo; bastion has no password auth |
| R9 | No RBAC — webhook runs as root | Medium | High | Future: create scoped `kubectl` ServiceAccount |
