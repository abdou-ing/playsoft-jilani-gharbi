# Variable Concept — Question Bank

This folder contains **19 questions** (q59–q77) covering Ansible fundamentals:
connectivity setup, variables, facts, inventory, ad-hoc commands, playbooks, and privilege escalation.

---

## Question Types

| Type | How it works | Graded by |
|---|---|---|
| `multi` | 4-choice MCQ, one correct answer, answers are shuffled | Student selects an answer |
| `button` | Hands-on task — student performs it in the terminal, then clicks **Check** | `_check.sh` script verifies the result |

---

## Question Index

### q59 — `multi`

| # | Topic |
|---|---|
| q59 | Ansible version installed on the control node |

---

### q60 — Environment Setup & Connectivity · `button`

| # | Task | What the check verifies | Check file |
|---|---|---|---|
| q60 | Configure `/etc/hosts`, create inventory, generate SSH key, `ssh-copy-id` to web1/web2/bd1, `ansible -m ping all` | Correct IPs in `/etc/hosts` · SSH key exists · `ansible ping` succeeds per host | `q60_check.sh` |

> **Foundation question.** All subsequent `button` questions include a skip-q60 guard in their setup script that automatically recreates the inventory, `/etc/hosts` entries, and SSH keys if q60 was skipped.

---

### q61–q64 — Fix & Write Playbooks · `button`

| # | Task | Playbook path | What the check verifies | Check file |
|---|---|---|---|---|
| q61 | Fix broken YAML quoting (`name: {{ pkg_name }}` → `name: "{{ pkg_name }}"`) and install `curl` on all hosts | `workspace/install_pkg.yml` | No unquoted `{{`, syntax OK, `curl` installed on web1 | `q61_check.sh` |
| q62 | Write a playbook with a `vars:` section defining `greeting` and print it with `debug` on all hosts | `workspace/vars_demo.yml` | `vars:` present, `greeting` defined, `debug:` used, runs OK | `q62_check.sh` |
| q63 | Write a playbook that displays `ansible_facts['distribution']` without `gather_facts: no` | `workspace/facts_demo.yml` | `debug:` present, `distribution` referenced, no `VARIABLE IS NOT DEFINED` | `q63_check.sh` |
| q64 | Write a playbook targeting `webservers` that installs `tree` only when `ansible_os_family == "Debian"` | `workspace/when_demo.yml` | `when:` + `ansible_os_family` present, `become:` set, `tree` installed on web1 | `q64_check.sh` |

---

### q65 — Inventory: Group of Groups · `button`

| # | Task | What the check verifies | Check file |
|---|---|---|---|
| q65 | Add `[all_servers:children]` to inventory with `webservers` and `dbservers` as child groups | Section present · both groups listed · `ansible all_servers --list-hosts` returns web1, web2, bd1 | `q65_check.sh` |

> Setup resets the `[all_servers:children]` block each run so re-attempts start clean.

---

### q66 — File Transfer · `button`

| # | Task | Playbook path | What the check verifies | Check file |
|---|---|---|---|---|
| q66 | Write a playbook that uses `copy` to push `files/hello.txt` to `/home/ansible_user/workspace/hello.txt` on `webservers` | `workspace/copy_demo.yml` | `copy:`, `src:`, `dest:` present · targets `webservers` · file exists on web1 and web2 | `q66_check.sh` |

> Setup creates `workspace/files/hello.txt` inside the container before presenting the question.

---

### q67–q77 — Hands-on Practice · `button`

| # | Task | Playbook / artifact path | What the check verifies | Depends on |
|---|---|---|---|---|
| q67 | Add `pkg_name=nginx` to `[webservers:vars]` in inventory | `inventory` | `[webservers:vars]` + `pkg_name=nginx` present | — |
| q68 | Write & run `debug_vars.yml` → print `pkg_name` with `debug` | `workspace/debug_vars.yml` | File exists, uses `debug:`, references `pkg_name`, runs OK | q67 |
| q69 | Write & run `install_pkg.yml` → install package from `pkg_name` variable | `workspace/install_pkg.yml` | nginx installed on web1 | q67 |
| q70 | Ad-hoc `uptime` on webservers → save to `uptime.txt` | `workspace/uptime.txt` | File exists with `load average` content | — |
| q71 | Write & run `create_file.yml` → `/tmp/hello.txt` with `Hello from Ansible` | `workspace/create_file.yml` | File content verified on web1 | — |
| q72 | Write & run `create_user.yml` → create user `devops` | `workspace/create_user.yml` | `id devops` succeeds on web1 | — |
| q73 | Write & run `multi_task.yml` → install + start nginx + write `index.html` "Welcome" | `workspace/multi_task.yml` | nginx active + `/var/www/html/index.html` content verified | q67 |
| q74 | Add `env=staging` to `[webservers:vars]` in inventory | `inventory` | `env=staging` present in inventory | q67 |
| q75 | Write & run `check_disk.yml` → `df -h` + `register: disk_info` + debug | `workspace/check_disk.yml` | `register:`, `disk_info`, `debug:` all present, runs OK | — |
| q76 | Write & run `full_setup.yml` → install + start + enable nginx with `become: yes` | `workspace/full_setup.yml` | nginx active AND enabled on web1 | q67 |
| q77 | Write & run `motd.yml` → `/etc/motd` with `Managed by Ansible` on all hosts | `workspace/motd.yml` | `/etc/motd` content verified on web1 | — |

#### Dependency chain (q67–q77)

```
q67 ──► q68   (pkg_name must exist in inventory)
    ──► q69   (pkg_name must exist)
    ──► q73   (pkg_name must exist)
    ──► q74   ([webservers:vars] section must exist)
    ──► q76   (pkg_name must exist)

q70, q71, q72, q75, q77 — fully independent, any order
```

#### Skip mechanism

Each `_setup.sh` patches missing prerequisites before outputting its question JSON. If a student skips q67, the next question's setup automatically appends the required inventory entries so no question is blocked.

---

## Summary

| Category | Questions | Count |
|---|---|---|
| MCQ (`multi`) | q59 | 1 |
| Hands-on (`button`) | q60–q66, q67–q77 | 18 |
| **Total** | q59–q77 | **19** |
