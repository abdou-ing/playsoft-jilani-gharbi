# Autoscaler — Goal, Specs, and Scenarios Found While Hardening It

This documents the Hetzner/Kubernetes CPU-based autoscaler: what it's for, what it
actually does today, and the real failure scenarios that surfaced while building
and testing it — most of which only show up under real timing/race conditions,
not in a code read-through.

---

## 1. Goal

Automatically grow and shrink the Kubernetes worker pool on Hetzner Cloud based on
real CPU load, with zero manual intervention, while guaranteeing:

- It **never conflicts** with the base cluster (`terraform-k8s`'s statically
  provisioned `hzn-k8s-master-1/2-dev`, `hzn-k8s-worker-1/2-dev`) — the autoscaler
  only ever adds/removes nodes on top of that floor, never below it, and never by
  guessing IP/name offsets (everything is discovered live from Hetzner each time).
- It **doesn't flap** — a 10-minute cooldown and a single mutex around scale
  operations prevent back-to-back scale-out/scale-in cycles.
- It **never leaves orphaned, billable infrastructure behind** on a failed attempt.
- **Monitoring (Prometheus + Grafana) is always correct** without any manual step —
  whatever Hetzner actually has is what gets scraped and shown, automatically.

## 2. Current specs

| | |
|---|---|
| Trigger (scale-out) | `WorkerAvgCPUCritical`: average CPU **across worker nodes only** >85%, sustained 2m |
| Trigger (scale-in) | `WorkerAvgCPULow`: average CPU **across worker nodes only** <20%, sustained 10m |
| Control-plane visibility (not a scaling trigger) | `MasterAvgCPUWarning`: average CPU across both masters >70%, sustained 5m — email only, masters aren't autoscaled |
| Cooldown | 600s between any two scale operations (either direction), enforced by one non-blocking lock that also prevents two scale operations running concurrently |
| New worker specs | `cx23`, golden snapshot image (`created_by=jilani,role=k8s_master_and_worker`), private network only (no public IP) |
| Naming / IP | `hzn-k8s-worker-N-dev`, `10.20.0.20+`, computed fresh from a live Hetzner API query every time — never a hardcoded offset |
| Webhook auth | `Authorization: Bearer <WEBHOOK_SHARED_SECRET>`, constant-time compare, refuses to start if unset |
| Webhook bind | `127.0.0.1:8080` only |
| Webhook concurrency | `ThreadingHTTPServer`; the HTTP response returns immediately, the actual scale operation (which can take many minutes) runs in a background thread |
| Rollback | A worker that's created but fails to join gets destroyed automatically via Terraform |
| Scope | Scale-in only ever removes a worker *this* autoscaler created (tracked via its own Terraform state's `worker_map` output) — never the base cluster's nodes |
| Monitoring sync | `targets.json` (Prometheus) and the `k8s-guacamole` Grafana dashboard's Nodename variable are both rewritten from the same live Hetzner discovery, on every scale event and every 60s in the background |
| Systemd hardening | Runs as `root` (needed for the SSH key + kubectl/terraform), but with `NoNewPrivileges`, `ProtectSystem=strict`, dropped capabilities, syscall filtering |

## 3. Scenarios exposed while building/testing this

These are real failures hit during development and load-testing — not theoretical.
Listed roughly in the order they were found.

### Security (found by review, not by testing)
- **Unauthenticated webhook** — anyone reaching port 8080 could trigger real
  infrastructure changes. Fixed with bearer-token auth, bound to loopback only.
- **Unbounded request body**, **no subprocess timeouts anywhere**, **predictable
  `/tmp` path for generated tfvars** (symlink/TOCTOU risk), **naive `"master" in
  name` substring matching**, **no Hetzner API pagination** (silently truncated at
  50 servers) — all fixed in the initial hardening pass.

### Orphaned infrastructure
- **`terraform apply` killed by its own timeout mid-creation.** The VM creation
  call had already been accepted by Hetzner's API; killing the local process with
  `SIGKILL` after 180s left a real, billable, untracked server with no
  corresponding Terraform state. Fix: removed the timeout from `terraform apply`
  specifically (kept it on read-only operations) — a slow apply is not the failure
  mode worth guarding against; an *interrupted* one is.
- **`scale_in()` could never clean up a worker that failed to join.** If a previous
  scale-out created a VM but never finished the Ansible join (e.g. due to the
  systemd bug below), the next scale-in's `kubectl drain` would fail with
  `NotFound` (the node was never registered) — and the code aborted right there,
  *before* ever reaching the Terraform destroy step. Fixed by treating a
  `NotFound` drain error as "nothing to drain, proceed to destroy."
- **The rollback path itself was a no-op in a drifted state.** `_rollback_new_worker`
  trusted that the pre-attempt snapshot (`managed`) didn't already contain the new
  worker's name — true in the clean case, false if state had already drifted (e.g.
  a previous orphan's VM was deleted out-of-band, manually, without Terraform
  knowing). Fixed by explicitly excluding the new worker's name from the rollback
  map rather than trusting the snapshot.

### Concurrency
- **Cooldown race under `ThreadingHTTPServer`.** Two concurrent requests could
  both read `last_scale`, both see the cooldown expired, and both launch
  `terraform apply` against the same state. Fixed by combining the cooldown check
  and the scale operation under one non-blocking mutex.
- **Alertmanager's notifier has a much shorter deadline than a scale operation
  takes.** `do_POST` originally blocked synchronously for the entire multi-minute
  `scale_out()`/`scale_in()` flow before responding — Alertmanager gave up and
  logged `context deadline exceeded` long before the operation (which was still
  succeeding) finished. Fixed by ACKing immediately and running the actual scale
  operation in a background thread.

### The systemd hardening itself broke things
- **`ProtectHome=read-only` blocked Ansible.** `ansible-playbook` (run by this
  service to join new workers) needs to write to `/root/.ansible/tmp/` for its
  local temp files — `ProtectHome=read-only` made every join attempt fail with
  `[Errno 30] Read-only file system`. Fixed by adding `/root/.ansible` to
  `ReadWritePaths` specifically, leaving the rest of `/root` (including the SSH
  key) read-only.

### Boot-time instability (still partially open — see §4)
- **SSH "recovers" once, then resets again seconds later.** The post-reboot wait
  loop accepted the *first* successful `echo ok` as proof the host was ready, then
  immediately handed off to Ansible. sshd can still be mid-restart at that exact
  moment (regenerating host keys on a freshly cloned instance) — the next real
  connection gets `kex_exchange_identification: read: Connection reset by peer`.
  Confirmed as a genuine timing race (reproduced once at ~4s after "recovery",
  succeeded another time only after ~1m36s of stable SSH) — not yet fixed.
- **`cloud-init.yml`'s `append: true`** on the network config `write_files` entry
  duplicates the `[Match]`/`[Network]` stanza on every clone, since the golden
  snapshot already contains the file from when this same script ran during the
  template's own creation. A likely contributing factor to the boot flakiness
  above. Not yet fixed.

### Observability
- **`targets.json` permission bug — the most disruptive single bug found.** The
  atomic-write helper used `tempfile.mkstemp()`, which creates files `0600`
  root-only. The webhook runs as root; Prometheus runs as its own unprivileged
  user. The moment the atomic-write pattern was introduced, Prometheus silently
  lost the ability to read its own scrape-target file — and because Prometheus's
  file-SD fails closed by keeping the *last successfully read* target list rather
  than crashing, there was **no visible error anywhere except Prometheus's own
  journal**. The autoscaler logs looked completely healthy; Grafana just quietly
  never showed new nodes. Fixed with an explicit `chmod 0o644` before the atomic
  rename.
- **Grafana's Nodename dropdown kept showing destroyed workers.** Root cause:
  `label_values()` (and `query_result()`) both ask Prometheus about data over the
  dashboard's *selected time range* (e.g. "Last 24 hours") — a node that existed
  at any point in that window shows up, regardless of current state. An attempted
  fix using `up{job="$job"} == 1` inside `label_values()` caused a hard PromQL
  parse error instead, because the `{...}` portion of that macro is sent to
  Prometheus's `/api/v1/series` as a plain label-selector, which doesn't support
  comparison operators at all. The actual fix: the webhook now owns the
  `Nodename` variable directly, rewriting it as a static `custom` list (no query,
  nothing to go stale) every time `targets.json` changes — see
  `_update_grafana_nodename_variable()` in `webhook.py`.

## 4. Known open items / accepted risk

- SSH-stability-check fix (require consecutive successful connections before
  handing off to Ansible, not just one) — designed, not yet implemented.
- `cloud-init.yml` `append: true` → `overwrite` fix — designed, not yet implemented.
- No remote Terraform state locking (local state file only) — fine solo, risky
  once more than one person/process can run `apply` concurrently.
- `controlPlaneEndpoint` is hardcoded to master-1's IP at cluster-init time —
  master-2 provides etcd/control-plane redundancy but isn't an active fallback;
  if master-1 goes down, no node (old or new) can join or re-register.
- `smtp_auth_password` is still hardcoded in plaintext in
  `ansible/roles/autoscaler/vars/main.yml`, already committed to git history —
  needs rotation and a move to vault/env, independent of everything above.
- SSH host-key checking is disabled (`StrictHostKeyChecking=no`) for
  bastion-to-node connections — accepted trade-off for a private network of
  ephemeral, frequently-recycled nodes; host-key pinning would need to handle
  re-keying on every scale-out/scale-in cycle.

## 5. Email alerting

Alertmanager has two receivers: `autoscaler` (the webhook — covered above) and
`email`, configured via SMTP in `ansible/roles/autoscaler/vars/main.yml`
(`smtp_smarthost`, `smtp_from`, `smtp_auth_username`, `smtp_auth_password`,
`alert_email_to`). Those values are credentials — never paste the real ones into
docs, tickets, or chat; they belong in the vars file (and per §4, that file should
move to vault — it currently isn't).

Routing logic (`alertmanager.yml.j2`):
- Alerts labeled `action: scale-out` or `action: scale-in` go **only** to the
  `autoscaler` webhook (`continue: false` stops further routing) — scale events do
  **not** also send an email by default.
- Everything else that fires (`NodeCPUWarning`, `NodeMemoryWarning/Critical`,
  `NodeDiskWarning/Critical`, `NodeDown`) falls through to the default `email`
  receiver.

To test email delivery without waiting for a real threshold breach, fire a
synthetic alert that's *not* tagged with a scale action (so it routes to email
instead of the webhook) — same mechanism as the manual scale-out test, different
labels:
```bash
curl -s -X POST http://localhost:9093/api/v2/alerts \
  -H "Content-Type: application/json" \
  -d '[{"labels": {"alertname": "ManualEmailTest", "severity": "warning", "team": "infra"}, "annotations": {"summary": "Manual email test"}, "startsAt": "'"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"'"}]'
```
Then check Alertmanager's own log for the SMTP send result:
```bash
journalctl -u alertmanager --no-pager | grep -i "email\|smtp"
```

## 6. Health checks

| Service | Command (run on the bastion) |
|---|---|
| Autoscaler webhook | `curl -i http://127.0.0.1:8080/healthz` → expect `200 ok` |
| Prometheus | `curl -i http://localhost:9090/-/healthy` and `/-/ready` |
| Alertmanager | `curl -i http://localhost:9093/-/healthy` |
| Grafana | `curl -i http://localhost:3000/api/health` → expect `"database": "ok"` |

The webhook's `/healthz` deliberately requires no auth (it reveals nothing
sensitive) so it's safe to hit from any local monitoring/uptime check on the
bastion itself.

## 7. Checking service status / logs

```bash
systemctl status prometheus alertmanager autoscaler grafana-server --no-pager
```

One-liner to see which of the four are actually active:
```bash
systemctl is-active prometheus alertmanager autoscaler grafana-server
```

Live logs, any combination of units at once:
```bash
journalctl -u autoscaler -u alertmanager -u prometheus -u grafana-server -f
```

## 8. If something changed, what to restart

The autoscaler role's tasks `notify` the right handler automatically whenever a
file they manage changes — re-running the playbook is the normal path and you
usually don't need to manually restart anything:
```bash
cd ansible && ansible-playbook site.yml --tags autoscaler   # or --tags grafana
```

For manual/quick iteration without a full playbook run, what needs restarting
depends on what changed:

| Changed | Action |
|---|---|
| `webhook.py` | `systemctl restart autoscaler` |
| `prometheus.yml` / `alerts.yml` | `curl -X POST localhost:9090/-/reload` (lighter than a restart — the systemd override already sets `--web.enable-lifecycle` to allow this) |
| `alertmanager.yml` | `systemctl restart alertmanager` (no lifecycle-reload endpoint configured for it here) |
| `targets.json` | nothing — Prometheus re-reads it automatically via `file_sd` every 30s |
| `k8s-guacamole.json` (Grafana dashboard) | nothing — Grafana's provisioner re-reads the dashboards folder every 30s |
| `*.tf` files | no service restart; just run `terraform plan`/`apply` next time the webhook (or you, manually) applies |
| `autoscaler.service` / `alertmanager.service` unit files | `systemctl daemon-reload` first, then restart the affected service |

## 9. Metrics exposed to Prometheus / shown in Grafana

Every node (masters and workers alike) runs `node_exporter` on `:9100`, scraped
under the single job `job="k8s-nodes"`. The metrics actually used by the alert
rules and the `k8s-guacamole` dashboard:

| Metric | Used for |
|---|---|
| `up{job="k8s-nodes"}` | target health (is this node currently being scraped) |
| `node_cpu_seconds_total{mode="idle"}` | CPU usage (all CPU alerts, CPU panels) |
| `node_memory_MemAvailable_bytes` / `node_memory_MemTotal_bytes` | memory usage/alerts |
| `node_filesystem_avail_bytes` / `node_filesystem_size_bytes` (root mount, excluding tmpfs) | disk usage/alerts |
| `node_uname_info` | the `nodename` label source for the (now webhook-managed) dashboard variable |

The `k8s-guacamole` dashboard (cloned from grafana.com ID 1860, "Node Exporter
Full") additionally renders network I/O and uptime panels from the same
`node_exporter` data — those aren't tied to any alert rule, just visualized.
Prometheus's own internal metrics (`prometheus_*`, `scrape_duration_seconds`, etc.)
are scraped by default but not currently used in any alert or dashboard panel.

## 10. Browsing Prometheus from your local machine

Same pattern as Grafana — Prometheus only listens on the bastion, so tunnel first:
```bash
ssh -i ~/.ssh/jilani -L 9090:localhost:9090 root@<bastion-ip> -N
```
Then open `http://localhost:9090` locally. Useful pages once there:
- `/targets` — which nodes are currently being scraped and their health
- `/alerts` — current state (inactive/pending/firing) of every alert rule
- `/graph` — run any PromQL ad hoc, e.g. the cluster-average CPU expression from §2
- `/config` — the exact config Prometheus loaded, useful for confirming a reload picked up a change
