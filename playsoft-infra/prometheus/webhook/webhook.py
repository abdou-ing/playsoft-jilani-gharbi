#!/usr/bin/env python3
import json
import logging
import subprocess
import time
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

    # Step 1: drain the node
    r = subprocess.run(
        ssh + [f"kubectl drain {hostname} --ignore-daemonsets --delete-emptydir-data --force"],
        capture_output=True, text=True
    )
    logging.info("kubectl drain: %s", r.stdout[-400:])
    if r.returncode != 0:
        logging.error("kubectl drain failed: %s", r.stderr)
        return False

    # Step 2: delete node from cluster
    subprocess.run(
        ssh + [f"kubectl delete node {hostname}"],
        capture_output=True, text=True
    )

    # Step 3: terraform apply with reduced count
    r = subprocess.run(
        ["terraform", f"-chdir={TF_DIR}", "apply", "-auto-approve",
         f"-var-file={TF_VARS}", f"-var=worker_count={new_count}"],
        capture_output=True, text=True
    )
    logging.info("Terraform stdout: %s", r.stdout[-800:])
    if r.returncode != 0:
        logging.error("Terraform scale-in failed: %s", r.stderr)
        return False

    # Step 4: update prometheus targets
    update_prometheus(new_count)
    logging.info("Scale-in complete — %d worker(s) remaining", new_count)
    return True


def update_prometheus(worker_count):
    targets = [f"{MASTER_IP}:9100"]
    for i in range(worker_count):
        targets.append(f"10.20.0.{WORKER_BASE_IP + i}:9100")

    targets_json = json.dumps([{"targets": targets, "labels": {"job": "k8s-nodes"}}], indent=2)
    Path(PROMETHEUS_CFG).write_text(targets_json)
    logging.info("Prometheus targets updated — scraping %d worker(s)", worker_count)


if __name__ == "__main__":
    logging.info("Autoscaler webhook listening on :8080")
    HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
