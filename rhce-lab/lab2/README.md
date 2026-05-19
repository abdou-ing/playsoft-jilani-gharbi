# Lab 2 — Ansible Playbooks

This lab covers writing and running Ansible playbooks: managing users, removing users, multi-play webserver setup, `lineinfile`, file copy, and directory creation.

## Prerequisites

- Lab 1 must be fully completed (SSH keys, inventory, `ansible.cfg` all configured on `control-node`)
- The podman compose stack must be running with `control-node`, `web1`, `web2`
- Run `lab2_env_setup.sh` before the lab starts (see Setup section below)

## File Layout

```
lab2/
├── q1_setup.sh      # Multiple-choice: ansible-playbook command syntax
├── q2_setup.sh      # Button: playbook to create alice and modify bob
├── q2_check.sh      # Check: alice exists with /bin/bash; bob has uid 2006
├── q3_setup.sh      # Button: playbook to remove charlie
├── q3_check.sh      # Check: charlie does not exist on any host
├── q4_setup.sh      # Button: multi-play webserver playbook
├── q4_check.sh      # Check: apache2 installed and active on group1
├── q5_setup.sh      # Button: add 10.0.0.1 myserver to /etc/hosts
├── q5_check.sh      # Check: entry present in /etc/hosts on all hosts
├── q6_setup.sh      # Button: copy config.json to /etc/myapp/
├── q6_check.sh      # Check: /etc/myapp/config.json exists on all hosts
├── q7_setup.sh      # Button: create /backup directory (mode 0755, root:root)
└── q7_check.sh      # Check: /backup exists with correct permissions
```

All files stay on the **host** — check scripts pipe themselves into `control-node` at runtime via `podman exec -i`.

## How Check Scripts Work

Identical delegation pattern to lab1:

```bash
_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi
```

The script pipes itself into `control-node` and runs there as `ansible_user` (via `cd /home/ansible_user`).

## Setup

### 1. Start the container stack

```bash
cd /home/svcuseran/redhat-example
sudo -u student podman-compose up -d
```

### 2. Run the lab2 environment setup script

This must be run **before each lab attempt** to reset the state of web1 and web2:

```bash
bash /home/svcuseran/redhat-example/lab2_env_setup.sh
```

What it does:
- Removes `alice` from web1 and web2 (Q2 will recreate her)
- Deletes and recreates `bob` with uid=1500 on web1 and web2 (Q2 will change to uid=2006)
- Deletes and recreates `charlie` on web1 and web2 (Q3 will remove him)
- Removes `/backup` from web1 and web2 (Q7 will create it)
- Removes `/etc/myapp` from web1 and web2 (Q6 will create it)
- Removes `10.0.0.1 myserver` from `/etc/hosts` on web1 and web2 (Q5 will add it)
- Creates `/home/ansible_user/playbooks/config.json` on `control-node` (needed by Q6)

## Running Setup Scripts (question display)

```bash
# Default language (English)
bash lab2/q1_setup.sh

# Specific language
bash lab2/q2_setup.sh fr
bash lab2/q4_setup.sh de
```

Supported languages: `en`, `fr`, `de`, `es`, `it`

## Running Check Scripts (grading)

```bash
bash lab2/q2_check.sh
bash lab2/q3_check.sh fr
```

### Expected outputs

| Result | JSON output |
|--------|-------------|
| Pass | `{"result": "0"}` |
| Fail | `{"result": "<error message>"}` |

### Debug mode

```bash
bash lab2/q2_check.sh debug
bash lab2/q7_check.sh debug fr
```

## Question Summary

| # | Type | Topic | What is checked |
|---|------|-------|-----------------|
| Q1 | Multiple choice | ansible-playbook command | `ansible-playbook site.yml` is correct |
| Q2 | Button | User management | `alice` exists with `/bin/bash`; `bob` has uid 2006 |
| Q3 | Button | Remove user | `charlie` absent from all hosts |
| Q4 | Button | Multi-play webserver | `apache2` installed and `active` on group1 |
| Q5 | Button | lineinfile | `10.0.0.1 myserver` present in `/etc/hosts` on all hosts |
| Q6 | Button | copy module | `/etc/myapp/config.json` exists on all hosts |
| Q7 | Button | file module (directory) | `/backup` exists with mode `755`, owner `root`, group `root` |

## Candidate Playbook Locations

All playbooks must be created inside `/home/ansible_user/playbooks/` (i.e. `/home/ansible_user/playbooks/`) on `control-node`:

| Question | Playbook path |
|----------|---------------|
| Q2 | `/home/ansible_user/playbooks/users.yml` |
| Q3 | `/home/ansible_user/playbooks/remove_user.yml` |
| Q4 | `/home/ansible_user/playbooks/webserver.yml` |
| Q5 | `/home/ansible_user/playbooks/add_hosts.yml` |
| Q6 | `/home/ansible_user/playbooks/copy_file.yml` |
| Q7 | `/home/ansible_user/playbooks/create_backup.yml` |

The file `/home/ansible_user/playbooks/config.json` is pre-created by `lab2_env_setup.sh` and used as the source file for Q6.

## End-to-End Test Sequence

After running `lab2_env_setup.sh` and having the candidate complete all exercises:

```bash
for i in 2 3 4 5 6 7; do
  echo "=== Q$i ===" && bash lab2/q${i}_check.sh
done
```

All should return `{"result": "0"}`.

## Notes

- Q4 uses `group1` (web1 only by default). Ensure the inventory assigns `web1` to `[group1]`.
- apache2 check uses `systemctl is-active apache2` inside the container — requires systemd or a service shim; verify containers support it before delivering the lab.
- Check scripts run `ansible` commands from `/home/ansible_user`, so `ansible.cfg` must be present there (completed in Lab 1 Q6).
