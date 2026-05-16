# Lab 1 — Ansible Environment Setup

This lab covers the foundational steps for configuring an Ansible control node: generating SSH keys, distributing them to managed hosts, creating an inventory file, and writing an `ansible.cfg`.

## Prerequisites

- The podman compose stack must be running with three containers: `control-node`, `web1`, `web2`
- Containers run under the `student` user (rootless podman)
- `ansible_user` is pre-created on all three containers

## File Layout

```
lab1/
├── q46_setup.sh     # Multiple-choice: ansible-core vs ansible package
├── q47_setup.sh     # Button: generate SSH key pair
├── q47_check.sh     # Check: key exists, valid format, no passphrase, correct perms, right length
├── q48_setup.sh     # Button: ssh-copy-id to web1 AND web2 (merged question)
├── q48_check.sh     # Check: passwordless SSH works on both hosts, key in authorized_keys, correct perms
├── q49_setup.sh     # Button: create inventory file
├── q49_check.sh     # Check: inventory contains web1 and web2
├── q50_setup.sh     # Button: create ansible.cfg
├── q50_check.sh     # Check: ansible.cfg has correct remote_user / inventory / become
├── q51_setup.sh     # Button: run ansible all -m ping
└── q51_check.sh     # Check: ping returns SUCCESS for web1 and web2
```

All files stay on the **host** — check scripts pipe themselves into `control-node` at runtime via `podman exec -i`.

## How Check Scripts Work

Each `q*_check.sh` contains this delegation block at the top:

```bash
_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi
```

When the container is running, the script pipes itself into `control-node` and runs there as `ansible_user`. When the container is not running, the script falls through and executes locally (useful for direct testing).

## Setup

No special setup script is needed for lab1. The containers arrive pre-configured with:
- `ansible_user` account on all nodes
- `ansible` / `ansible-core` installed on `control-node`
- The `student` user's SSH keys already injected into `ansible_user@web1` and `ansible_user@web2` (the candidate recreates this as part of the lab)

Start the stack:

```bash
cd /home/svcuseran/redhat-example
sudo -u student podman-compose up -d
```

Optionally apply the terminal banners to web1 and web2:

```bash
bash /home/svcuseran/redhat-example/web_banner_setup.sh
```

## Running Setup Scripts (question display)

Each `q*_setup.sh` outputs a JSON object consumed by the InstaLab platform. Call them directly to inspect the question:

```bash
# Default language (English)
bash lab1/q46_setup.sh

# French
bash lab1/q47_setup.sh fr
bash lab1/q48_setup.sh fr
```

Supported languages: `en`, `fr`

## Running Check Scripts (grading)

Call a check script directly from the host. The script auto-detects the container and delegates into it:

```bash
bash lab1/q47_check.sh
bash lab1/q48_check.sh fr
```

### Expected outputs

| Result | JSON output |
|--------|-------------|
| Pass | `{"result": "0"}` |
| Fail | `{"result": "<error message>"}` |

### Debug mode

Prefix any check script with `debug` to enable `set -eoux` tracing:

```bash
bash lab1/q47_check.sh debug
bash lab1/q49_check.sh debug fr
```

## Question Summary

| File | Type | Topic | What is checked |
|------|------|-------|-----------------|
| q46 | Multiple choice | Package naming | `ansible-core` vs `ansible` |
| q47 | Button | SSH keygen | Key exists, valid format, no passphrase, perms 600, min 2048 bits (RSA), pub matches |
| q48 | Button | SSH copy-id web1 + web2 | Passwordless SSH works on both hosts as `ansible_user`, key in `authorized_keys`, correct perms |
| q49 | Button | Inventory file | `/home/ansible_user/inventory` has `web1` and `web2` |
| q50 | Button | ansible.cfg | `remote_user=ansible_user`, `inventory=...`, `become=true` present |
| q51 | Button | ansible ping | `ansible all -m ping` returns SUCCESS for both hosts |

## End-to-End Test Sequence

Run all checks in order after completing the lab steps:

```bash
for i in 47 48 49 50 51; do
  echo "=== Q$i ===" && bash lab1/q${i}_check.sh
done
```

All should return `{"result": "0"}`.
