# Variable Concept — Question Bank

This folder contains **42 questions** (q59–q100) covering Ansible fundamentals:
variables, facts, ansible.cfg, inventory, ad-hoc commands, playbooks, and privilege escalation.

---

## Question Types

| Type | How it works | Graded by |
|---|---|---|
| `multi` | 4-choice MCQ, one correct answer, answers are shuffled | Student selects an answer |
| `button` | Hands-on task — student performs it in the terminal, then clicks **Check** | `_check.sh` script verifies the result |

---

## Question Index

### Block 1 — Variables & Facts Theory (q59–q68) · `multi`

| # | Topic | Correct answer |
|---|---|---|
| q59 | Three types of Ansible variables | fact, variable, magic variable |
| q60 | Invalid variable name (hyphen rule) | `my-package` is invalid |
| q61 | Where gathered facts are stored | `ansible_facts` |
| q62 | Preferred notation for facts | Square brackets: `ansible_facts['hostname']` |
| q63 | Highest variable precedence | `-e key=value` on command line |
| q64 | Custom facts directory on managed hosts | `/etc/ansible/facts.d` |
| q65 | Play header to disable fact gathering | `gather_facts: no` |
| q66 | Magic variable containing all hosts + vars | `hostvars` |
| q67 | When to wrap variable reference in quotes | When value starts with `{{` |
| q68 | ansible-vault command to change password | `rekey` |

---

### Block 2 — Broken Playbook: Find the Bug (q69–q71) · `multi`

The broken YAML is shown **directly in the question**. The student reads it and picks the correct diagnosis.

| # | Bug in the playbook | Correct answer |
|---|---|---|
| q69 | `name: {{ pkg_name }}` — missing double quotes | Variable reference needs quotes |
| q70 | `web-package:` / `web-service:` — hyphens in variable names | Hyphens not allowed in variable names |
| q71 | `gather_facts: no` but task uses `ansible_facts['distribution']` | Facts disabled but task requires them |

---

### Block 3 — Run a Command to Verify (q72–q75) · `multi`

Student must run each option and observe the output to find the correct answer.

| # | Task | Correct command |
|---|---|---|
| q72 | Verify custom facts on all hosts | `ansible all -m setup -a 'filter=ansible_local'` |
| q73 | Read vault file without decrypting to disk | `ansible-vault view secrets.yaml` |
| q74 | Find OS distribution of all managed hosts | `ansible all -m setup -a 'filter=ansible_distribution'` |
| q75 | Verify if user charlie exists on all hosts | `ansible all -m command -a 'id charlie'` |

---

### Block 4 — ansible.cfg & Inventory Basics (q76–q80) · `multi`

| # | Topic | Correct answer |
|---|---|---|
| q76 | ansible.cfg section for inventory/roles/remote_user | `[defaults]` |
| q77 | Inventory syntax for a group of groups | `[webservers:children]` |
| q78 | ansible.cfg setting for SSH login username | `remote_user` |
| q79 | What `become = true` does in ansible.cfg | Escalates to root via sudo |
| q80 | Command that checks connectivity AND privilege escalation | `ansible all -a 'id'` |

---

### Block 5 — Beginner Commands & Playbook Concepts (q81–q89) · `multi`

| # | Topic | Correct answer |
|---|---|---|
| q81 | Command to show installed Ansible version | `ansible --version` |
| q82 | Count hosts in a group (inventory shown in question) | 3 |
| q83 | Module used for ad-hoc connectivity test | `ping` |
| q84 | What `hosts:` defines in a playbook | Target group or hosts |
| q85 | Module to copy file from control node to managed hosts | `copy` |
| q86 | Default inventory file path | `/etc/ansible/hosts` |
| q87 | Playbook keyword that labels a task | `name` |
| q88 | Command to run a playbook | `ansible-playbook` |
| q89 | What `become: yes` does in a playbook | Privilege escalation (sudo) |

> **Note:** q89 and q79 cover the same `become` concept from different angles — q79 is the `ansible.cfg` config context, q89 is the playbook keyword context.

---

### Block 6 — Hands-on Practice (q90–q100) · `button`

Student performs the task in the terminal, then clicks **Check**. Each question has a corresponding `_check.sh` verification script.

| # | Task | What the check verifies | Depends on |
|---|---|---|---|
| q90 | Add `pkg_name=nginx` to `[webservers:vars]` in inventory | `[webservers:vars]` + `pkg_name=nginx` present | — |
| q91 | Write & run `debug_vars.yml` → print `pkg_name` | File exists, uses `debug:`, references `pkg_name`, runs OK | q90 |
| q92 | Write & run `install_pkg.yml` → install from `pkg_name` | nginx installed on web1 | q90 |
| q93 | Ad-hoc `uptime` on webservers → save to `uptime.txt` | File exists with `load average` content | — |
| q94 | Write & run `create_file.yml` → `/tmp/hello.txt` with `Hello from Ansible` | File content verified on web1 | — |
| q95 | Write & run `create_user.yml` → create user `devops` | `id devops` succeeds on web1 | — |
| q96 | Write & run `multi_task.yml` → install + start + `index.html` "Welcome" | nginx active + `/var/www/html/index.html` content | q90 |
| q97 | Add `env=staging` to `[webservers:vars]` in inventory | `env=staging` present in inventory | q90 |
| q98 | Write & run `check_disk.yml` → `df -h` + `register: disk_info` + debug | `register:`, `disk_info`, `debug:` all present, runs OK | — |
| q99 | Write & run `full_setup.yml` → `become:yes` + install + start + enable | nginx active AND enabled on web1 | q90 |
| q100 | Write & run `motd.yml` → `/etc/motd` with `Managed by Ansible` on all | `/etc/motd` content verified on web1 | — |

#### Dependency chain

```
q90  ──► q91   (pkg_name variable must exist)
     ──► q92   (pkg_name variable must exist)  ──► q96 / q99  (nginx must be installed)
     ──► q96   (pkg_name variable must exist)
     ──► q97   ([webservers:vars] section must exist)
     ──► q99   (pkg_name variable must exist)

q93, q94, q95, q98, q100  — fully independent, any order
```

#### Skip mechanism

Every `_check.sh` accepts a `skip` argument. When the student skips a question, the check script **silently auto-performs the task** so downstream questions are not blocked.

```bash
# Called by the platform when student clicks Skip:
./q90_check.sh skip        # English
./q90_check.sh fr skip     # French
```

| Skipped | Auto-action |
|---|---|
| q90 | Appends `[webservers:vars]` + `pkg_name=nginx` to inventory |
| q91 | Writes `debug_vars.yml` and runs it silently |
| q92 | Writes `install_pkg.yml` and installs nginx silently |
| q93 | Runs `uptime` ad-hoc and saves output to `uptime.txt` |
| q94 | Writes `create_file.yml` and creates `/tmp/hello.txt` |
| q95 | Writes `create_user.yml` and creates user `devops` |
| q96 | Writes `multi_task.yml`, starts nginx, creates `index.html` |
| q97 | Appends `env=staging` to `[webservers:vars]` in inventory |
| q98 | Writes `check_disk.yml` and runs it silently |
| q99 | Writes `full_setup.yml` and enables nginx at boot |
| q100 | Writes `motd.yml` and writes `/etc/motd` on all hosts |

---


## Summary

| Category | Count |
|---|---|
| MCQ (`multi`) | 31 (q59–q89) |
| Hands-on (`button`) | 11 (q90–q100) |
| **Total** | **42** |
