# RHCE Practice Exam — White Test

A complete 18-question RHCE practice exam adapted for Ubuntu containers with Ansible.

## Lab Environment

| Component | Value |
|-----------|-------|
| Control node | `control-node` container (podman) |
| Managed nodes | `web1` (dev, prod, balancers), `web2` (test, prod) |
| Playbooks dir | `/home/ansible_user/workspace/` (`/home/ansible_user/playbooks/`) |
| Inventory | `/home/ansible_user/workspace/inventory` |
| ansible.cfg | `/home/ansible_user/workspace/ansible.cfg` |
| Roles dir | `/home/ansible_user/workspace/roles/` |
| Collections dir | `/home/ansible_user/workspace/mycollections/` |
| Remote user | `ansible_user` |
| SSH key | `~/.ssh/ansible_key` |
| OS | Ubuntu (use `apt`, `apache2` — no SELinux) |

## Questions Overview

| # | File | Topic |
|---|------|-------|
| Q01 | `q01_*.sh` | Configure Ansible: inventory + ansible.cfg |
| Q02 | `q02_*.sh` | Ad-hoc: apt-pack.sh with apt_repository module |
| Q03 | `q03_*.sh` | packages.yml: php, mariadb-client, build-essential, apt upgrade |
| Q04 | `q04_*.sh` | timesync.yml: chrony NTP sync with 172.25.254.250 |
| Q05 | `q05_*.sh` | Apache role + newrole.yml: apache2, Jinja2 index.html |
| Q06 | `q06_*.sh` | roles/requirements.yml: balancer + phpinfo from GitHub |
| Q07 | `q07_*.sh` | balance.yml: 3-play playbook with Galaxy roles |
| Q08 | `q08_*.sh` | web.yml: webdev group, /webdev dir 02775, symlink, index.html |
| Q09 | `q09_*.sh` | ansible-vault: vault.yml encrypted with atenorth |
| Q10 | `q10_*.sh` | Jinja2 template + gen_hosts.yml: /etc/myhosts |
| Q11 | `q11_*.sh` | hwreport.yml + hwreport.j2: /root/hwreport.txt |
| Q12 | `q12_*.sh` | issue.yml: /etc/issue conditional per group |
| Q13 | `q13_*.sh` | Rekey vault: secret.yml from curabete to newvare |
| Q14 | `q14_*.sh` | create_user.yml + user_list.yml with vault passwords |
| Q15 | `q15_*.sh` | storage.yml: LVM block/rescue/always |
| Q16 | `q16_*.sh` | cron.yml: natasha cron job */2 min |
| Q17 | `q17_*.sh` | mycollections/requirements.yml: ansible.posix + community.general |
| Q18 | `q18_*.sh` | selinux.yml: ansible.posix.selinux permissive/targeted |

## Running the Check Scripts

### Individual question check
```bash
# Run from the host machine
bash q01_check.sh
bash q01_check.sh fr       # French output
bash q01_check.sh debug    # Debug mode (set -eoux)
```

### Full exam grading (from playsoft-infra/ansible/)
```bash
ansible-playbook -i inventory.ini rhce_exam_check.yml
```

## Check Script Pattern

All check scripts follow the same pattern:

```bash
#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

declare -A messages_en=( ["key"]="English error message" )
declare -A messages_fr=( ["key"]="French error message" )

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user
# ... checks ...
echo '{"result": "0"}'
```

**How it works:**
1. If running on the host and `control-node` container is up, the script pipes itself into the container via `podman exec`
2. Inside the container it runs as `ansible_user` context
3. Returns `{"result": "0"}` for pass or `{"result": "error message"}` for fail

## Setup Script Pattern

Setup scripts output JSON describing the question for the web interface:

```bash
#!/bin/bash
lang="${1:-en}"
# ... question text, hint, instructions with example commands ...
jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": ..., "type": "button", "tags": "ansible,rhce,..."}'
```

## Expected Output

Check scripts return JSON:
- **Pass:** `{"result": "0"}`
- **Fail:** `{"result": "Descriptive error message in English or French"}`

Setup scripts return JSON:
```json
{
    "question": "Question text...",
    "plateforme_required": "container",
    "os_required": "ubuntu",
    "type": "button",
    "hint": "Hint text...",
    "instructions": [
        {"instruction": "Step 1:", "command": "```yaml\n...\n```"},
        {"instruction": "Step 2:", "command": "```bash\n...\n```"}
    ],
    "text": "Check",
    "tags": "ansible,rhce,..."
}
```

## Question Details

### Q01 — Configure Ansible
Create `/home/ansible_user/workspace/inventory` with groups: `[dev]` web1, `[test]` web2, `[prod]` web1+web2, `[balancers]` web1, `[webservers:children]` dev+test+prod. Create `/home/ansible_user/workspace/ansible.cfg` with inventory, roles_path, collections_path, remote_user=ansible_user, become=true.

### Q02 — Ad-hoc apt_repository
Create `/home/ansible_user/workspace/apt-pack.sh` running ansible ad-hoc commands to add two Ubuntu apt repositories using `community.general.apt_repository`.

### Q03 — Package management
`packages.yml`: install `php` + `mariadb-client` on dev/test/prod, install `build-essential` + run `apt upgrade` on dev only.

### Q04 — Time synchronization
`timesync.yml`: install `chrony`, configure `/etc/chrony/chrony.conf` with NTP server `172.25.254.250 iburst`, start+enable `chrony` service.

### Q05 — Apache role
Create `/home/ansible_user/workspace/roles/apache/` with tasks (install apache2, ufw port 80) and template `templates/index.html.j2` → `Welcome to {{ fqdn }} on {{ ip }}`. Playbook `newrole.yml` runs it on `webservers`.

### Q06 — Galaxy role requirements
Create `/home/ansible_user/workspace/roles/requirements.yml` with two entries: `balancer` from geerlingguy/ansible-role-apache and `phpinfo` from geerlingguy/ansible-role-php.

### Q07 — balance.yml
Three-play playbook: play1 gathers facts from all, play2 runs `balancer` role on balancers group, play3 runs `phpinfo` role on webservers group.

### Q08 — Web directory setup
`web.yml` (targets dev): create group `webdev`, directory `/webdev` mode 02775 + group webdev + owner www-data, symlink `/var/www/html/mywebdev` → `/webdev`, file `/webdev/index.html` with content `Development`.

### Q09 — Ansible Vault
Create `/home/ansible_user/workspace/vault.yml` encrypted with password `atenorth` containing `dev_pass: wakennym` and `mgr_pass: rocky`. Store password in `/home/ansible_user/workspace/password.txt` with mode 0600.

### Q10 — Jinja2 hosts template
Create `/home/ansible_user/workspace/hosts.j2` with a for loop over all hosts outputting IP + FQDN + hostname. `gen_hosts.yml` deploys it to `/etc/myhosts` on dev hosts.

### Q11 — Hardware report
`hwreport.yml` with `hwreport.j2` template. Deploys `/root/hwreport.txt` on all hosts with FQDN, memory, BIOS version, sda/sdb sizes. Uses block/rescue for missing devices.

### Q12 — Conditional /etc/issue
`issue.yml`: set `/etc/issue` to `Development` on dev hosts, `Test` on test hosts, `Production` on prod hosts using `copy` module with `when:` conditions.

### Q13 — Rekey vault
`/home/ansible_user/workspace/secret.yml` is pre-created encrypted with `curabete`. Rekey it so the new password is `newvare`. Old password must no longer work.

### Q14 — User accounts
Create `/home/ansible_user/workspace/user_list.yml` with users (adam/gabriel/lucifer). Create `/home/ansible_user/workspace/create_user.yml` using `vars_files: [user_list.yml, vault.yml]`. Developers (adam, lucifer) on dev+test in group `devops` with `dev_pass`. Manager (gabriel) on prod in group `opsmgr` with `mgr_pass`.

### Q15 — LVM Storage
`storage.yml`: block tries to create LV `data` (1500m) in VG `research`. Rescue handles "VG not found" and "insufficient free space" (creates 800m instead). Always creates ext4 on `/dev/research/data`.

### Q16 — Cron job
`cron.yml`: create user `natasha` on all hosts, add cron job every `*/2` minutes running `logger "EX294 in progress"` as user natasha.

### Q17 — Collections
Create `/home/ansible_user/workspace/mycollections/requirements.yml` with `ansible.posix` and `community.general`. Install with `ansible-galaxy collection install -r mycollections/requirements.yml -p mycollections/`.

### Q18 — SELinux/AppArmor
`selinux.yml`: use `ansible.posix.selinux` module on all hosts with `state: permissive` and `policy: targeted`. Use `ignore_errors: true` since Ubuntu doesn't have SELinux.

## Infra Files

- `playsoft-infra/ansible/rhce_exam_check.yml` — Ansible playbook to run all 18 checks
- `playsoft-infra/ansible/vars/rhce_exam_tasks.yml` — Task definitions with script paths
