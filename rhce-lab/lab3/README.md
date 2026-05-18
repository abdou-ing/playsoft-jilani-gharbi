# Lab 3 — Variables and Ansible Facts

This lab covers using Ansible variables (`vars`, `vars_files`) and Ansible Facts to generate dynamic content on managed hosts.

## Prerequisites

- Lab 1 must be fully completed (SSH keys, inventory, `ansible.cfg` all configured on `control-node`)
- The podman compose stack must be running with `control-node`, `web1`, `web2`

## File Layout

```
lab3/
├── q59_setup.sh     # Multiple-choice: which fact variable holds total RAM in MB
├── q60_setup.sh     # Button: report.yml — 5 facts (HOST, MEMORY, BIOS, SDA, SDB) → /root/report.txt
├── q60_check.sh     # Check: /root/report.txt has correct fact values on all hosts
├── q61_setup.sh     # Button: vars_motd.yml — vars: with company_name → /etc/motd
├── q61_check.sh     # Check: /etc/motd contains hostname + PlaySoft on all hosts
├── q62_setup.sh     # Button: my_package.yml + install_from_vars.yml — vars_files to install curl
├── q62_check.sh     # Check: my_package.yml exists, vars_files used, curl installed on all hosts
├── q63_setup.sh     # Button: network_info.yml — IP + FQDN facts → /root/network_info.txt
├── q63_check.sh     # Check: /root/network_info.txt has correct IP and FQDN on all hosts
├── q64_setup.sh     # Button: os_report.yml — OS + VERSION + KERNEL facts → /root/os_report.txt
├── q64_check.sh     # Check: /root/os_report.txt has correct OS, VERSION, KERNEL on all hosts
├── q65_setup.sh     # Button: register_vars.yml — register command output → /root/registered_hostname.txt
├── q65_check.sh     # Check: register used, .stdout written, content matches hostname
├── q66_setup.sh     # Button: set_fact_vars.yml — set_fact env_label → /root/env_label.txt
├── q66_check.sh     # Check: set_fact used, env_label is '<hostname>-prod'
├── q67_setup.sh     # Button: magic_vars.yml — inventory_hostname + group_names → /root/inventory_info.txt
├── q67_check.sh     # Check: magic vars used, INVENTORY_NAME and GROUPS correct
├── q68_setup.sh     # Button: dict_vars.yml — app_config dict → /root/app_config.txt
└── q68_check.sh     # Check: dict vars used, APP/PORT/ENV match expected values
```

All files stay on the **host** — check scripts pipe themselves into `control-node` at runtime via `podman exec -i`.

## How Check Scripts Work

Identical delegation pattern to lab1/lab2:

```bash
_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi
```

The script pipes itself into `control-node` and runs there as `ansible_user` (via `cd /home/ansible_user`).

## Setup

Start the container stack if not already running:

```bash
cd /home/svcuseran/redhat-example
sudo -u student podman-compose up -d
```

No environment reset script is needed — Lab 3 is self-contained and does not depend on state from previous labs.

## Running Setup Scripts (question display)

```bash
# Default language (English)
bash lab3/q59_setup.sh
bash lab3/q60_setup.sh
bash lab3/q61_setup.sh
bash lab3/q62_setup.sh
bash lab3/q63_setup.sh
bash lab3/q64_setup.sh

# French
bash lab3/q60_setup.sh fr
bash lab3/q61_setup.sh fr
```

Supported languages: `en`, `fr`

## Running Check Scripts (grading)

```bash
bash lab3/q60_check.sh
bash lab3/q61_check.sh
bash lab3/q62_check.sh
bash lab3/q63_check.sh
bash lab3/q64_check.sh
```

### Expected outputs

| Result | JSON output |
|--------|-------------|
| Pass | `{"result": "0"}` |
| Fail | `{"result": "<error message>"}` |

### Debug mode

```bash
bash lab3/q60_check.sh debug
bash lab3/q61_check.sh debug fr
```

## Question Summary

| # | Type | Topic | What is checked |
|---|------|-------|-----------------|
| Q59 | Multiple choice | Ansible Facts — which variable holds total RAM in MB | `ansible_memtotal_mb` is correct |
| Q60 | Button | Facts + `lineinfile` → `/root/report.txt` | Correct fact vars used; HOST, MEMORY, BIOS, SDA_DISK_SIZE, SDB_DISK_SIZE in file |
| Q61 | Button | `vars:` + `copy` → `/etc/motd` | `company_name: PlaySoft` in `vars:`, motd contains hostname + PlaySoft |
| Q62 | Button | `vars_files:` + `apt` → install `curl` | `my_package.yml` with `pkg_name: curl`, `vars_files:` used, curl installed |
| Q63 | Button | Facts + `lineinfile` → `/root/network_info.txt` | `ansible_default_ipv4.address` + `ansible_fqdn`; IP and FQDN match |
| Q64 | Button | Facts + `lineinfile` → `/root/os_report.txt` | `ansible_distribution`, `ansible_distribution_version`, `ansible_kernel`; values match |
| Q65 | Button | `register` + `copy` → `/root/registered_hostname.txt` | `register:` used, `.stdout` written to file, content matches actual hostname |
| Q66 | Button | `set_fact` + `copy` → `/root/env_label.txt` | `set_fact:` used, `env_label` is `<hostname>-prod` |
| Q67 | Button | Magic vars + `lineinfile` → `/root/inventory_info.txt` | `inventory_hostname` + `group_names` used; INVENTORY_NAME and GROUPS correct |
| Q68 | Button | Dict `vars:` + `lineinfile` → `/root/app_config.txt` | `app_config` dict with dot notation; APP=myapp, PORT=8080, ENV=production |

## Candidate Playbook Locations

| Question | File(s) |
|----------|---------|
| Q60 | `~/playbooks/report.yml` |
| Q61 | `~/playbooks/vars_motd.yml` |
| Q62 | `~/playbooks/my_package.yml` + `~/playbooks/install_from_vars.yml` |
| Q63 | `~/playbooks/network_info.yml` |
| Q64 | `~/playbooks/os_report.yml` |
| Q65 | `~/playbooks/register_vars.yml` |
| Q66 | `~/playbooks/set_fact_vars.yml` |
| Q67 | `~/playbooks/magic_vars.yml` |
| Q68 | `~/playbooks/dict_vars.yml` |

## End-to-End Test Sequence

After the candidate completes all exercises:

```bash
for q in 60 61 62 63 64 65 66 67 68; do
  echo "=== Q${q} ===" && bash lab3/q${q}_check.sh
done
```

All should return `{"result": "0"}`.
