#!/usr/bin/env python3
import json
import logging
import os
import subprocess
import threading
import time
import urllib.request
import urllib.error
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

COOLDOWN       = 600
TF_DIR         = "/opt/infra/prometheus/terraform"
TF_VARS        = "env/dev.tfvars"
ANSIBLE_DIR    = "/opt/infra/prometheus/ansible"
JOIN_PLAYBOOK  = f"{ANSIBLE_DIR}/join-worker.yml"
PROMETHEUS_CFG = "/opt/infra/prometheus/config/targets.json"
SSH_KEY        = "/root/.ssh/jilani"
MASTER_IP      = "10.20.0.10"
WORKER_BASE_IP = 11

last_scale = 0


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        global last_scale
        length = int(self.headers.get("Content-Length", 0))
        if length == 0:
            self.send_response(400)
            self.end_headers()
            return
        try:
            body = json.loads(self.rfile.read(length))
        except json.JSONDecodeError:
            self.send_response(400)
            self.end_headers()
            return

        for alert in body.get("alerts", []):
            is_firing    = alert["status"] == "firing"
            action       = alert["labels"].get("action")
            cooled_down  = time.time() - last_scale > COOLDOWN

            if is_firing and action == "scale-out" and cooled_down:
                instance = alert["labels"].get("instance", "unknown")
                logging.info("Scale-out triggered by %s", instance)
                if scale_out():
                    last_scale = time.time()
            elif is_firing and action == "scale-in" and cooled_down:
                logging.info("Scale-in triggered — cluster CPU low")
                if scale_in():
                    last_scale = time.time()
            elif is_firing and not cooled_down:
                remaining = int(COOLDOWN - (time.time() - last_scale))
                logging.info("Cooldown active — %ds remaining", remaining)

        self.send_response(200)
        self.end_headers()

    def log_message(self, *args):
        pass


def get_current_worker_count():
    r = subprocess.run(
        ["terraform", f"-chdir={TF_DIR}", "output", "-json", "worker_private_ips"],
        capture_output=True, text=True
    )
    if r.returncode != 0:
        logging.error("terraform output failed: %s", r.stderr)
        return None
    return len(json.loads(r.stdout))


def scale_out():
    current = get_current_worker_count()
    if current is None:
        return False

    new_count = current + 1
    new_worker_ip = f"10.20.0.{WORKER_BASE_IP + current}"
    logging.info("Scaling %d → %d workers, new IP: %s", current, new_count, new_worker_ip)

    # Step 1: terraform apply
    r = subprocess.run(
        ["terraform", f"-chdir={TF_DIR}", "apply", "-auto-approve",
         f"-var-file={TF_VARS}", f"-var=worker_count={new_count}"],
        capture_output=True, text=True
    )
    logging.info("Terraform stdout: %s", r.stdout[-800:])
    if r.returncode != 0:
        logging.error("Terraform failed: %s", r.stderr)
        return False

    # Step 2: wait for SSH to become available
    logging.info("Waiting for SSH on %s ...", new_worker_ip)
    ssh_base = ["ssh", "-i", SSH_KEY, "-o", "StrictHostKeyChecking=no",
                "-o", "ConnectTimeout=5", f"root@{new_worker_ip}"]
    for _ in range(36):
        if subprocess.run(ssh_base + ["echo ok"], capture_output=True).returncode == 0:
            break
        time.sleep(5)
    else:
        logging.error("Node %s never became reachable via SSH", new_worker_ip)
        return False

    # Step 3: cloud-init's last runcmd is a reboot; wait for it to complete.
    # Poll cloud-init status: if SSH drops first (reboot started) or status
    # reaches "done", break out then wait for SSH to be stable again.
    logging.info("Waiting for cloud-init + reboot on %s ...", new_worker_ip)
    deadline = time.time() + 300
    post_reboot = False
    while time.time() < deadline:
        r = subprocess.run(ssh_base + ["cloud-init status 2>/dev/null"],
                           capture_output=True, text=True)
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
            if subprocess.run(ssh_base + ["echo ok"], capture_output=True).returncode == 0:
                break
            time.sleep(5)
        else:
            logging.error("Node %s did not recover after reboot", new_worker_ip)
            return False

    # Step 4: build inventory — bastion is on the same private network as workers,
    # so reach them directly without a jump host
    inventory = f"""[masters]
k8s-master ansible_host={MASTER_IP} ansible_ssh_private_key_file={SSH_KEY}

[new_workers]
k8s-worker-{new_count} ansible_host={new_worker_ip} ansible_ssh_private_key_file={SSH_KEY}

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
"""
    inv_path = "/tmp/join-inventory.ini"
    Path(inv_path).write_text(inventory)

    # Step 5: run ansible join playbook
    r = subprocess.run(
        ["ansible-playbook", "-i", inv_path, JOIN_PLAYBOOK],
        capture_output=True, text=True, cwd=ANSIBLE_DIR,
        stdin=subprocess.DEVNULL
    )
    logging.info("Ansible stdout: %s", r.stdout[-800:])
    if r.returncode != 0:
        logging.error("Ansible failed: %s", r.stderr)
        return False

    # Step 6: add new node to prometheus scrape targets
    update_prometheus(new_count)
    return True


def scale_in():
    current = get_current_worker_count()
    if current is None:
        return False
    if current <= 1:
        logging.info("Scale-in skipped — already at minimum (1 worker)")
        return False

    new_count  = current - 1
    remove_ip  = f"10.20.0.{WORKER_BASE_IP + current - 1}"
    hostname   = f"hzn-k8s-worker-{current}-jilani"
    logging.info("Scaling %d → %d workers, removing %s (%s)", current, new_count, hostname, remove_ip)

    ssh = ["ssh", "-i", SSH_KEY, "-o", "StrictHostKeyChecking=no",
           "-o", "ConnectTimeout=10", f"root@{MASTER_IP}"]

    # Step 1: remove from Prometheus BEFORE draining so NodeDown never fires
    update_prometheus(new_count)
    logging.info("Removed %s from Prometheus targets before drain", remove_ip)

    # Step 2: drain the node
    r = subprocess.run(
        ssh + [f"kubectl drain {hostname} --ignore-daemonsets --delete-emptydir-data --force"],
        capture_output=True, text=True
    )
    logging.info("kubectl drain: %s", r.stdout[-400:])
    if r.returncode != 0:
        logging.error("kubectl drain failed: %s", r.stderr)
        # Rollback: re-add the IP to prometheus since drain failed
        update_prometheus(current)
        return False

    # Step 3: delete node from cluster
    subprocess.run(
        ssh + [f"kubectl delete node {hostname}"],
        capture_output=True, text=True
    )

    # Step 4: terraform apply with reduced count
    r = subprocess.run(
        ["terraform", f"-chdir={TF_DIR}", "apply", "-auto-approve",
         f"-var-file={TF_VARS}", f"-var=worker_count={new_count}"],
        capture_output=True, text=True
    )
    logging.info("Terraform stdout: %s", r.stdout[-800:])
    if r.returncode != 0:
        logging.error("Terraform scale-in failed: %s", r.stderr)
        return False

    logging.info("Scale-in complete — %d worker(s) remaining", new_count)
    return True


def update_prometheus(worker_count):
    entries = [{"targets": [f"{MASTER_IP}:9100"], "labels": {"job": "k8s-nodes", "nodename": "hzn-k8s-master-jilani"}}]
    for i in range(worker_count):
        ip = f"10.20.0.{WORKER_BASE_IP + i}:9100"
        entries.append({"targets": [ip], "labels": {"job": "k8s-nodes", "nodename": f"hzn-k8s-worker-{i + 1}-jilani"}})

    Path(PROMETHEUS_CFG).write_text(json.dumps(entries, indent=2))
    logging.info("Prometheus targets updated — scraping %d worker(s)", worker_count)


def node_exporter_up(ip, timeout=3):
    """Return True only if node_exporter is reachable on the given IP."""
    try:
        urllib.request.urlopen(f"http://{ip}:9100/metrics", timeout=timeout)
        return True
    except Exception:
        return False


def discover_from_hcloud():
    """Query Hetzner API and return all k8s nodes as [(name, ip)] — no health check."""
    token = os.environ.get("HCLOUD_TOKEN", "")
    if not token:
        logging.warning("HCLOUD_TOKEN not set — skipping Hetzner discovery")
        return None
    try:
        req = urllib.request.Request(
            "https://api.hetzner.cloud/v1/servers?per_page=50",
            headers={"Authorization": f"Bearer {token}"}
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read())
    except Exception as e:
        logging.error("Hetzner API error: %s", e)
        return None

    masters, workers = [], []
    for server in data.get("servers", []):
        name = server["name"]
        private_nets = server.get("private_net", [])
        if not private_nets:
            continue
        ip = private_nets[0]["ip"]
        if "master" in name:
            masters.append((name, ip))
        elif "worker" in name:
            workers.append((name, ip))

    return masters + workers


def build_entries(nodes):
    """Build targets.json entries list from [(name, ip), ...] pairs."""
    return [
        {"targets": [f"{ip}:9100"], "labels": {"job": "k8s-nodes", "nodename": name}}
        for name, ip in sorted(nodes, key=lambda x: x[1])
    ]


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
            Path(PROMETHEUS_CFG).write_text(json.dumps(new_entries, indent=2))


if __name__ == "__main__":
    # Startup sync: discover nodes from Hetzner API and write targets.json
    nodes = discover_from_hcloud()
    if nodes:
        entries = build_entries(nodes)
        Path(PROMETHEUS_CFG).write_text(json.dumps(entries, indent=2))
        logging.info("Startup sync: %s", [(n, ip) for n, ip in nodes])
    else:
        logging.warning("Startup sync failed — Hetzner API unavailable, keeping existing targets.json")

    # Background thread: re-discover every 60s
    t = threading.Thread(target=sync_loop, daemon=True)
    t.start()
    logging.info("Node discovery thread started (interval: 60s)")

    logging.info("Autoscaler webhook listening on :8080")
    HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
