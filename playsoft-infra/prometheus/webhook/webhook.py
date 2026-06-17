#!/usr/bin/env python3
import hmac
import json
import logging
import os
import re
import stat
import subprocess
import tempfile
import threading
import time
import urllib.request
import urllib.error
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

COOLDOWN           = 600
TF_DIR             = "/opt/infra/prometheus/terraform"
TF_VARS            = "env/dev.tfvars"
SCRATCH_DIR        = "/etc/autoscaler/run"   # 0700, root-only — avoids the shared-/tmp TOCTOU risk
ANSIBLE_DIR        = "/opt/infra/prometheus/ansible"
JOIN_PLAYBOOK      = f"{ANSIBLE_DIR}/join-worker.yml"
PROMETHEUS_CFG     = "/opt/infra/prometheus/config/targets.json"
GRAFANA_DASHBOARD  = "/var/lib/grafana/dashboards/k8s-guacamole.json"
SSH_KEY            = "/root/.ssh/jilani"
WORKER_BASE_IP     = 20   # 10.20.0.20+, same range as the base hzn-k8s-worker-1/2-dev nodes
WORKER_ENV         = "dev"
WORKER_NAME_RE     = re.compile(r"^hzn-k8s-worker-(\d+)-" + re.escape(WORKER_ENV) + r"$")
MASTER_NAME_RE     = re.compile(r"^hzn-k8s-master-(\d+)-" + re.escape(WORKER_ENV) + r"$")
MAX_BODY_BYTES     = 1 * 1024 * 1024   # reject oversized webhook payloads outright
WEBHOOK_SHARED_SECRET = os.environ.get("WEBHOOK_SHARED_SECRET", "")

# Subprocess timeouts — without these, a hung terraform/ssh/ansible call wedges
# the whole process forever (worse before ThreadingHTTPServer, but still bad after).
TF_OUTPUT_TIMEOUT  = 30
SSH_TIMEOUT        = 15
KUBECTL_TIMEOUT    = 60
ANSIBLE_TIMEOUT    = 600

# Serializes all writes to PROMETHEUS_CFG — sync_loop() and the request thread
# (via scale_out/scale_in) can both write it concurrently otherwise.
targets_lock = threading.Lock()

# Same purpose as targets_lock, for GRAFANA_DASHBOARD — kept separate since
# they're different files and there's no reason to serialize one behind the other.
grafana_lock = threading.Lock()

last_scale = 0
# Non-blocking: serializes scale_out/scale_in AND guards last_scale together, so
# two concurrent requests can never both pass the cooldown check and launch
# overlapping `terraform apply` runs against the same state.
scale_lock = threading.Lock()


# HTTP handler for Alertmanager webhooks: triggers scale-out/scale-in based on firing alerts.
class Handler(BaseHTTPRequestHandler):
    def _authorized(self):
        """Constant-time check of the 'Authorization: Bearer <secret>' header.
        Without this, anyone who can reach this port can puppet Terraform/kubectl as root."""
        expected = f"Bearer {WEBHOOK_SHARED_SECRET}"
        got = self.headers.get("Authorization", "")
        return hmac.compare_digest(got, expected)

    def do_GET(self):
        # Liveness/readiness probe — does not require auth, reveals nothing sensitive.
        if self.path == "/healthz":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok")
            return
        self.send_response(404)
        self.end_headers()

    def do_POST(self):
        if not self._authorized():
            logging.warning("Rejected unauthorized webhook request from %s", self.client_address[0])
            self.send_response(401)
            self.end_headers()
            return

        try:
            length = int(self.headers.get("Content-Length", 0))
        except ValueError:
            self.send_response(400)
            self.end_headers()
            return
        if length == 0:
            self.send_response(400)
            self.end_headers()
            return
        if length > MAX_BODY_BYTES:
            logging.warning("Rejected oversized webhook body (%d bytes) from %s", length, self.client_address[0])
            self.send_response(413)
            self.end_headers()
            return
        try:
            body = json.loads(self.rfile.read(length))
        except json.JSONDecodeError:
            self.send_response(400)
            self.end_headers()
            return

        try:
            self._handle_alerts(body.get("alerts", []))
        except Exception:
            logging.exception("Unhandled error processing webhook payload")
            self.send_response(500)
            self.end_headers()
            return

        self.send_response(200)
        self.end_headers()

    def _handle_alerts(self, alerts):
        for alert in alerts:
            try:
                is_firing = alert.get("status") == "firing"
                action = alert.get("labels", {}).get("action")
            except AttributeError:
                logging.warning("Skipping malformed alert entry: %r", alert)
                continue

            if is_firing and action == "scale-out":
                instance = alert.get("labels", {}).get("instance", "unknown")
                logging.info("Scale-out triggered by %s", instance)
                _try_scale(scale_out, "Scale-out")
            elif is_firing and action == "scale-in":
                logging.info("Scale-in triggered — cluster CPU low")
                _try_scale(scale_in, "Scale-in")

    def log_message(self, *args):
        pass


# Checks the cooldown + mutual-exclusion lock synchronously (so do_POST can respond
# fast either way), then runs scale_fn() itself in a background thread. scale_out/
# scale_in can take many minutes (terraform apply + SSH wait + Ansible join) —
# Alertmanager's notifier has a much shorter deadline than that and will log
# "context deadline exceeded" if the webhook doesn't ACK quickly, regardless of
# whether the scale operation itself goes on to succeed.
def _try_scale(scale_fn, label):
    global last_scale
    if not scale_lock.acquire(blocking=False):
        logging.info("%s skipped — another scale operation is already in progress", label)
        return
    remaining = COOLDOWN - (time.time() - last_scale)
    if remaining > 0:
        logging.info("Cooldown active — %ds remaining", int(remaining))
        scale_lock.release()
        return

    def _run():
        global last_scale
        try:
            if scale_fn():
                last_scale = time.time()
        finally:
            scale_lock.release()

    logging.info("%s started in background", label)
    threading.Thread(target=_run, daemon=True).start()


def get_master_ip():
    """Return the IP of the first master (lowest IP), or None if unavailable."""
    nodes = discover_from_hcloud()
    if nodes:
        masters = sorted([(name, ip) for name, ip in nodes if "master" in name], key=lambda x: x[1])
        if masters:
            return masters[0][1]
    logging.error("get_master_ip: could not discover master IP from Hetzner API")
    return None


def get_managed_workers():
    """Workers this Terraform state (the autoscaler) currently owns: {name: ip}.

    Deliberately scoped to this state's own resources — never includes the
    base hzn-k8s-worker-1/2-dev nodes owned by terraform-k8s.
    """
    try:
        r = subprocess.run(
            ["terraform", f"-chdir={TF_DIR}", "output", "-json", "worker_map"],
            capture_output=True, text=True, timeout=TF_OUTPUT_TIMEOUT
        )
    except subprocess.TimeoutExpired:
        logging.error("terraform output timed out after %ds", TF_OUTPUT_TIMEOUT)
        return None
    if r.returncode != 0:
        logging.error("terraform output failed: %s", r.stderr)
        return None
    return json.loads(r.stdout)


def discover_all_workers():
    """{index: (name, ip)} for every hzn-k8s-worker-N-dev server in Hetzner,
    regardless of which Terraform state created it (terraform-k8s or this one).
    Used to find the next free index/IP without ever colliding with the base cluster.
    """
    nodes = discover_from_hcloud()
    if nodes is None:
        return None
    found = {}
    for name, ip in nodes:
        m = WORKER_NAME_RE.match(name)
        if m:
            found[int(m.group(1))] = (name, ip)
    return found


def apply_workers(workers_map):
    """Apply the autoscaler's desired worker set. workers_map is the FULL
    {name: ip} map this state should own afterwards (existing + new, or
    existing minus one for scale-in)."""
    # Written into a 0700 root-only directory with a fresh random name each time —
    # avoids a predictable path in shared /tmp that another local process could
    # race or symlink-swap between our write and terraform's read.
    os.makedirs(SCRATCH_DIR, exist_ok=True, mode=0o700)
    fd, tmp_path = tempfile.mkstemp(dir=SCRATCH_DIR, suffix=".auto.tfvars.json")
    try:
        with os.fdopen(fd, "w") as f:
            json.dump({"workers": workers_map}, f)
        os.chmod(tmp_path, stat.S_IRUSR | stat.S_IWUSR)

        # No timeout here on purpose: killing `terraform apply` mid-flight (SIGKILL)
        # can create a real Hetzner server and get killed before state is written,
        # leaving an untracked, billable orphan — worse than just waiting it out.
        # The request thread blocks, but ThreadingHTTPServer means that only stalls
        # this one scale operation, not the whole webhook.
        r = subprocess.run(
            ["terraform", f"-chdir={TF_DIR}", "apply", "-auto-approve",
             f"-var-file={TF_VARS}", f"-var-file={tmp_path}"],
            capture_output=True, text=True
        )
    finally:
        os.unlink(tmp_path)

    logging.info("Terraform stdout: %s", r.stdout[-800:])
    if r.returncode != 0:
        logging.error("Terraform failed: %s", r.stderr)
        return False
    return True


def _ssh_run(ssh_base, remote_cmd, timeout=SSH_TIMEOUT):
    try:
        return subprocess.run(ssh_base + [remote_cmd], capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired as e:
        return subprocess.CompletedProcess(ssh_base, 255, stdout="", stderr=str(e))


def _rollback_new_worker(managed, new_worker_name):
    """Best-effort teardown of a worker that was created but never finished joining
    the cluster — otherwise it's an orphaned, un-hardened VM left running forever.

    Explicitly excludes new_worker_name rather than trusting that `managed`
    doesn't already contain it. If Terraform state had already drifted from
    reality (e.g. a previous orphan's VM was deleted out-of-band without going
    through Terraform), `managed` could already include this name, which would
    make a naive apply_workers(managed) a no-op — leaving the orphan in place.
    """
    logging.error("Rolling back %s after a failed scale-out", new_worker_name)
    rollback_map = {n: ip for n, ip in managed.items() if n != new_worker_name}
    if not apply_workers(rollback_map):
        logging.error("Rollback failed — %s may still exist in Hetzner/Terraform state; needs manual cleanup", new_worker_name)


# Discovers the next free worker index/IP from live Hetzner state, creates that
# server via Terraform, waits for it to come up, then joins it to the cluster.
def scale_out():
    managed = get_managed_workers()
    if managed is None:
        return False
    all_workers = discover_all_workers()
    if all_workers is None:
        return False

    next_index = max(all_workers.keys(), default=0) + 1
    used_ips = {ip for _, ip in all_workers.values()}
    offset = WORKER_BASE_IP + next_index - 1
    while f"10.20.0.{offset}" in used_ips:
        offset += 1
    new_worker_ip = f"10.20.0.{offset}"
    new_worker_name = f"hzn-k8s-worker-{next_index}-{WORKER_ENV}"

    logging.info("Scaling out: adding %s (%s)", new_worker_name, new_worker_ip)

    # Step 1: create the VM. Everything after this point must roll back on
    # failure, or the VM is left running but never joined to the cluster.
    new_managed = dict(managed)
    new_managed[new_worker_name] = new_worker_ip
    if not apply_workers(new_managed):
        return False

    # Step 2: wait for SSH to become available
    logging.info("Waiting for SSH on %s ...", new_worker_ip)
    ssh_base = ["ssh", "-i", SSH_KEY, "-o", "StrictHostKeyChecking=no",
                "-o", "ConnectTimeout=5", f"root@{new_worker_ip}"]
    for _ in range(36):
        if _ssh_run(ssh_base, "echo ok").returncode == 0:
            break
        time.sleep(5)
    else:
        logging.error("Node %s never became reachable via SSH", new_worker_ip)
        _rollback_new_worker(managed, new_worker_name)
        return False

    # Step 3: cloud-init's last runcmd is a reboot; wait for it to complete.
    # Poll cloud-init status: if SSH drops first (reboot started) or status
    # reaches "done", break out then wait for SSH to be stable again.
    logging.info("Waiting for cloud-init + reboot on %s ...", new_worker_ip)
    deadline = time.time() + 300
    post_reboot = False
    while time.time() < deadline:
        r = _ssh_run(ssh_base, "cloud-init status 2>/dev/null")
        if r.returncode != 0:
            # SSH gone — reboot is in progress
            break
        if "done" in r.stdout:
            post_reboot = True  # cloud-init finished (already past reboot)
            break
        time.sleep(5)

    if not post_reboot:
        logging.info("Reboot detected on %s, waiting for SSH to recover ...", new_worker_ip)
        for _ in range(60):
            if _ssh_run(ssh_base, "echo ok").returncode == 0:
                break
            time.sleep(5)
        else:
            logging.error("Node %s did not recover after reboot", new_worker_ip)
            _rollback_new_worker(managed, new_worker_name)
            return False

    # Step 4: build inventory — bastion is on the same private network as workers,
    # so reach them directly without a jump host
    master_ip = get_master_ip()
    if master_ip is None:
        _rollback_new_worker(managed, new_worker_name)
        return False
    inventory = f"""[masters]
k8s-master ansible_host={master_ip} ansible_ssh_private_key_file={SSH_KEY}

[new_workers]
{new_worker_name} ansible_host={new_worker_ip} ansible_ssh_private_key_file={SSH_KEY}

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
"""
    os.makedirs(SCRATCH_DIR, exist_ok=True, mode=0o700)
    inv_fd, inv_path = tempfile.mkstemp(dir=SCRATCH_DIR, suffix=".join-inventory.ini")
    with os.fdopen(inv_fd, "w") as f:
        f.write(inventory)

    try:
        # Step 5: run ansible join playbook
        try:
            r = subprocess.run(
                ["ansible-playbook", "-i", inv_path, JOIN_PLAYBOOK],
                capture_output=True, text=True, cwd=ANSIBLE_DIR,
                stdin=subprocess.DEVNULL, timeout=ANSIBLE_TIMEOUT
            )
        except subprocess.TimeoutExpired:
            logging.error("Ansible join playbook timed out after %ds", ANSIBLE_TIMEOUT)
            _rollback_new_worker(managed, new_worker_name)
            return False
    finally:
        os.unlink(inv_path)

    logging.info("Ansible stdout: %s", r.stdout[-800:])
    if r.returncode != 0:
        logging.error("Ansible failed: %s", r.stderr)
        _rollback_new_worker(managed, new_worker_name)
        return False

    # Step 6: add new node to prometheus scrape targets
    update_prometheus_from_hcloud()
    return True


# Drains, deletes, and destroys the most recently added autoscaler-managed worker.
def scale_in():
    # Only ever look at workers THIS terraform state created — the base
    # hzn-k8s-worker-1/2-dev nodes from terraform-k8s are never candidates here.
    managed = get_managed_workers()
    if managed is None:
        return False
    if not managed:
        logging.info("Scale-in skipped — no autoscaler-managed workers to remove")
        return False

    # Pick the worker to remove: the highest-indexed one this state owns,
    # i.e. the most recently added autoscaler node.
    def _index(name):
        m = WORKER_NAME_RE.match(name)
        return int(m.group(1)) if m else -1

    remove_name = max(managed, key=_index)
    remove_ip = managed[remove_name]
    logging.info("Scaling in: removing %s (%s)", remove_name, remove_ip)

    # Need a master to run kubectl drain/delete against.
    master_ip = get_master_ip()
    if master_ip is None:
        return False
    ssh = ["ssh", "-i", SSH_KEY, "-o", "StrictHostKeyChecking=no",
           "-o", "ConnectTimeout=10", f"root@{master_ip}"]

    # Step 1: remove from Prometheus BEFORE draining so NodeDown never fires
    update_prometheus_from_hcloud(exclude_ip=remove_ip)
    logging.info("Removed %s from Prometheus targets before drain", remove_ip)

    # Step 2: drain the node — evict pods so workloads reschedule elsewhere
    # before the VM is destroyed.
    try:
        r = subprocess.run(
            ssh + [f"kubectl drain {remove_name} --ignore-daemonsets --delete-emptydir-data --force"],
            capture_output=True, text=True, timeout=KUBECTL_TIMEOUT
        )
    except subprocess.TimeoutExpired:
        logging.error("kubectl drain timed out after %ds", KUBECTL_TIMEOUT)
        update_prometheus_from_hcloud()
        return False
    logging.info("kubectl drain: %s", r.stdout[-400:])
    if r.returncode != 0:
        if "NotFound" in r.stderr:
            # Node was never joined (e.g. a previous scale-out failed before the
            # Ansible join step) — nothing to drain, proceed straight to destroying it.
            logging.info("Node %s not found in cluster — skipping drain, proceeding to destroy", remove_name)
        else:
            logging.error("kubectl drain failed: %s", r.stderr)
            # Rollback: re-add the IP to prometheus since drain failed
            update_prometheus_from_hcloud()
            return False

    # Step 3: delete node from cluster — removes its Node object from the
    # Kubernetes API so it stops showing up once the VM is gone.
    try:
        subprocess.run(
            ssh + [f"kubectl delete node {remove_name}"],
            capture_output=True, text=True, timeout=KUBECTL_TIMEOUT
        )
    except subprocess.TimeoutExpired:
        logging.warning("kubectl delete node timed out after %ds — continuing, terraform will still destroy the VM", KUBECTL_TIMEOUT)

    # Step 4: terraform apply with the worker removed from the managed map —
    # terraform diffs this against state and destroys just that one VM.
    new_managed = {n: ip for n, ip in managed.items() if n != remove_name}
    if not apply_workers(new_managed):
        logging.error("Terraform scale-in failed")
        return False

    logging.info("Scale-in complete — %d autoscaler-managed worker(s) remaining", len(new_managed))
    return True


# Writes targets.json atomically (temp file + rename) under a lock — sync_loop()'s
# background thread and scale_out/scale_in (request thread) both write this file,
# and a non-atomic write risks Prometheus's file_sd reading a half-written file.
def _write_targets(entries):
    with targets_lock:
        dest = Path(PROMETHEUS_CFG)
        fd, tmp_path = tempfile.mkstemp(dir=dest.parent, suffix=".tmp")
        try:
            with os.fdopen(fd, "w") as f:
                json.dump(entries, f, indent=2)
            # mkstemp creates the file 0600 (root-only) — but this webhook runs as
            os.chmod(tmp_path, 0o644)
            os.replace(tmp_path, dest)
        except Exception:
            os.unlink(tmp_path)
            raise


# Keeps the k8s-guacamole dashboard's Nodename variable in lockstep with reality,
# the same way _write_targets() does for Prometheus — called from the same places,
# with the same node list, so there's only one source of truth for "what exists".
#
# Why not just fix the PromQL query instead: label_values()/query_result() both ask
# Prometheus about data over the dashboard's selected time range (e.g. "Last 24h"),
# so a destroyed node lingers in the dropdown until it ages out of that range —
# that's what bit us with a stale worker-3 entry. A static "custom" variable has no
# query to go stale; it's just whatever was last written here.
#
# Deliberately isolated from the autoscaling path: a Grafana-sync failure must never
# fail a scale-out/scale-in, so every failure mode here logs and returns rather than
# raising. Patches the existing file in place rather than re-fetching from
# grafana.com — the webhook has no business making internet calls on every scale
# event, and the dashboard's panels/layout aren't its concern, only this one variable.
def _update_grafana_nodename_variable(nodes):
    dest = Path(GRAFANA_DASHBOARD)
    if not dest.exists():
        return  # Grafana role not deployed (yet) — nothing to keep in sync

    names = sorted({name for name, _ in nodes})
    if not names:
        # Hetzner returned nothing — almost certainly a transient discovery hiccup
        # (see discover_from_hcloud's own error handling), not a real empty cluster.
        # Leaving the dropdown as-is beats wiping it down to zero options.
        return

    with grafana_lock:
        try:
            dashboard = json.loads(dest.read_text())
        except Exception as e:
            logging.warning("Grafana Nodename sync: could not read %s: %s", dest, e)
            return

        variable = next(
            (v for v in dashboard.get("templating", {}).get("list", []) if v.get("name") == "nodename"),
            None
        )
        if variable is None:
            logging.warning("Grafana Nodename sync: no 'nodename' variable found in %s", dest)
            return

        # Keep the current selection if it's still valid, instead of yanking the
        # dashboard to a different node underneath whoever's looking at it.
        previous = variable.get("current", {}).get("value")
        selected = previous if previous in names else names[0]

        variable["type"] = "custom"
        variable["query"] = ",".join(names)
        variable["options"] = [{"text": n, "value": n, "selected": n == selected} for n in names]
        variable["current"] = {"text": selected, "value": selected, "selected": True}

        try:
            fd, tmp_path = tempfile.mkstemp(dir=dest.parent, suffix=".tmp")
            try:
                with os.fdopen(fd, "w") as f:
                    json.dump(dashboard, f, indent=2)
                os.chmod(tmp_path, 0o644)  # grafana runs as its own user, not root — see _write_targets
                os.replace(tmp_path, dest)
            except Exception:
                os.unlink(tmp_path)
                raise
        except Exception as e:
            logging.warning("Grafana Nodename sync: failed to write %s: %s", dest, e)
            return

    logging.info("Grafana Nodename variable synced — %d node(s)", len(names))


# Called after scale-out/scale-in to refresh what Prometheus scrapes.
def update_prometheus_from_hcloud(exclude_ip=None):
    """Rebuild targets.json from the live Hetzner server list (masters + all workers,
    base cluster and autoscaler alike) — no hardcoded offsets or counts involved."""
    # Ask Hetzner for the current truth instead of trusting any local count/offset.
    nodes = discover_from_hcloud()
    if nodes is None:
        logging.warning("update_prometheus: Hetzner API unavailable, leaving targets.json untouched")
        return
    # Used during scale-in to drop the node being removed before it's actually gone.
    if exclude_ip:
        nodes = [(name, ip) for name, ip in nodes if ip != exclude_ip]
    # Overwrite targets.json wholesale — Prometheus picks up the new list on its
    # next scrape interval thanks to file_sd.
    _write_targets(build_entries(nodes))
    try:
        _update_grafana_nodename_variable(nodes)
    except Exception as e:
        logging.warning("Grafana Nodename sync failed (non-fatal): %s", e)
    logging.info("Prometheus targets updated — %d node(s)", len(nodes))


# Health check used to avoid adding a node to Prometheus before it's actually scrapeable.
def node_exporter_up(ip, timeout=3):
    """Return True only if node_exporter is reachable on the given IP."""
    try:
        urllib.request.urlopen(f"http://{ip}:9100/metrics", timeout=timeout)
        return True
    except Exception:
        return False


# Single source of truth for "what nodes actually exist" — every other
# function that needs node state goes through this rather than trusting local state.
def discover_from_hcloud():
    """Query Hetzner API and return all k8s nodes as [(name, ip)] — no health check."""
    token = os.environ.get("HCLOUD_TOKEN", "")
    if not token:
        logging.warning("HCLOUD_TOKEN not set — skipping Hetzner discovery")
        return None

    servers = []
    page = 1
    try:
        while True:
            req = urllib.request.Request(
                f"https://api.hetzner.cloud/v1/servers?per_page=50&page={page}",
                headers={"Authorization": f"Bearer {token}"}
            )
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = json.loads(resp.read())
            servers.extend(data.get("servers", []))
            next_page = data.get("meta", {}).get("pagination", {}).get("next_page")
            if not next_page:
                break
            page = next_page
    except Exception as e:
        logging.error("Hetzner API error: %s", e)
        return None

    masters, workers = [], []
    for server in servers:
        name = server["name"]
        private_nets = server.get("private_net", [])
        if not private_nets:
            continue
        ip = private_nets[0]["ip"]
        if MASTER_NAME_RE.match(name):
            masters.append((name, ip))
        elif WORKER_NAME_RE.match(name):
            workers.append((name, ip))

    return masters + workers


# Converts (name, ip) pairs into the Prometheus file_sd JSON format.
def build_entries(nodes):
    """Build targets.json entries list from [(name, ip), ...] pairs."""
    return [
        {"targets": [f"{ip}:9100"], "labels": {"job": "k8s-nodes", "nodename": name}}
        for name, ip in sorted(nodes, key=lambda x: x[1])
    ]


# Keeps targets.json correct even outside of scale events (e.g. a node dies
# unexpectedly, or someone provisions/removes a server manually).
def sync_loop():
    """Background thread: re-discover nodes every 60s and update targets.json if changed.

    Rules:
    - New server (in Hetzner, not in targets): add only if node_exporter is up
    - Existing server (in targets): keep even if node_exporter is down (Prometheus fires NodeDown)
    - Deleted server (not in Hetzner): always remove
    """
    while True:
        time.sleep(60)
        nodes = discover_from_hcloud()
        if nodes is None:
            continue

        try:
            current_entries = json.loads(Path(PROMETHEUS_CFG).read_text())
            current_map = {
                e["targets"][0].split(":")[0]: e["labels"].get("nodename", "")
                for e in current_entries
            }
        except Exception:
            current_map = {}

        hcloud_map = {ip: name for name, ip in nodes}

        merged = {}
        # Keep existing targets if server still exists on Hetzner (even if node_exporter is down)
        for ip, nodename in current_map.items():
            if ip in hcloud_map:
                merged[ip] = hcloud_map[ip]
        # Add new servers only if node_exporter is already up (avoids NodeDown during provisioning)
        for ip, name in hcloud_map.items():
            if ip not in merged and node_exporter_up(ip):
                merged[ip] = name

        new_entries = [
            {"targets": [f"{ip}:9100"], "labels": {"job": "k8s-nodes", "nodename": name}}
            for ip, name in sorted(merged.items(), key=lambda x: x[0])
        ]
        new_targets = sorted(f"{ip}:9100" for ip in merged)
        current_targets = sorted(t for e in current_entries for t in e["targets"]) if current_map else []

        if new_targets != current_targets:
            logging.info("Node discovery: targets changed %s → %s", current_targets, new_targets)
            _write_targets(new_entries)
            try:
                _update_grafana_nodename_variable([(name, ip) for ip, name in merged.items()])
            except Exception as e:
                logging.warning("Grafana Nodename sync failed (non-fatal): %s", e)


# Entry point: seed targets.json once at startup, then serve the webhook
# while a background thread keeps targets.json in sync every 60s.
if __name__ == "__main__":
    # Fail closed: an empty secret would make every request's "Bearer " header
    # match an empty expected value, silently disabling auth. Refuse to start instead.
    if not WEBHOOK_SHARED_SECRET:
        logging.critical("WEBHOOK_SHARED_SECRET is not set — refusing to start with auth disabled")
        raise SystemExit(1)

    # Startup sync: discover nodes from Hetzner API and write targets.json
    nodes = discover_from_hcloud()
    if nodes:
        _write_targets(build_entries(nodes))
        try:
            _update_grafana_nodename_variable(nodes)
        except Exception as e:
            logging.warning("Grafana Nodename sync failed (non-fatal): %s", e)
        logging.info("Startup sync: %s", [(n, ip) for n, ip in nodes])
    else:
        logging.warning("Startup sync failed — Hetzner API unavailable, keeping existing targets.json")

    # Background thread: re-discover every 60s
    t = threading.Thread(target=sync_loop, daemon=True)
    t.start()
    logging.info("Node discovery thread started (interval: 60s)")

    # Bound to loopback only — Alertmanager runs on the same host and calls
    # http://localhost:8080; there is no reason for this to be reachable off-box.
    logging.info("Autoscaler webhook listening on 127.0.0.1:8080")
    ThreadingHTTPServer(("127.0.0.1", 8080), Handler).serve_forever()
