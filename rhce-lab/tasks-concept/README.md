# Tasks Concept — Question Bank

This folder contains **10 questions** (q1–q10) covering Ansible task control from Chapter 7:
loops, conditionals (`when`), `register`, handlers, error handling (`failed_when`, `ignore_errors`, `force_handlers`), blocks (`block/rescue/always`), and the `fail` module.

---

## Question Types

| Type | How it works | Graded by |
|---|---|---|
| `button` | Hands-on task — student performs it in the terminal, then clicks **Check** | `_check.sh` script verifies the result |

All 10 questions are `button` type.

---

## Skip guard

Every setup script contains a **skip-foundation guard** that automatically creates the inventory, `/etc/hosts` entries, and SSH keys if the student has not yet completed the connectivity setup. All questions are fully independent and can be attempted in any order.

---

## Question Index

### q1 — Loop to Install Packages · `button`

| # | Task | Playbook path | What the check verifies | Check file |
|---|---|---|---|---|
| q1 | Write a playbook using `loop` to install `curl` and `tree` on webservers with `{{ item }}` | `workspace/loop_install.yml` | `loop:` present · `item` referenced · `curl` and `tree` installed on web1 | `q1_check.sh` |

---

### q2 — Loop with Multivalued Vars File · `button`

| # | Task | Files | What the check verifies | Check file |
|---|---|---|---|---|
| q2 | Create `vars/pkglist.yml` with `name`/`state` pairs, write a playbook using `vars_files` + `loop` with `item.name` and `item.state` | `workspace/vars/pkglist.yml` · `workspace/loop_vars.yml` | vars file has `packages:` list with `name:` and `state:` · playbook uses `vars_files`, `loop`, `item.name`, `item.state` · playbook runs OK | `q2_check.sh` |

---

### q3 — `when` with `os_family` · `button`

| # | Task | Playbook path | What the check verifies | Check file |
|---|---|---|---|---|
| q3 | Write a playbook that installs `nmap` on all hosts only when `ansible_facts['os_family'] == "Debian"` | `workspace/when_os.yml` | `when:` present · `os_family` referenced · `Debian` in condition · `nmap` installed on web1 | `q3_check.sh` |

---

### q4 — `register` + `when` · `button`

| # | Task | Playbook path | What the check verifies | Check file |
|---|---|---|---|---|
| q4 | Check `systemctl is-active ssh` with `ignore_errors: yes`, register result, print debug only when `result.rc == 0` | `workspace/register_when.yml` | `register:` present · `ignore_errors:` present · `when: result.rc` used · `debug:` present · syntax OK · runs OK | `q4_check.sh` |

---

### q5 — `loop` + `when` Combined · `button`

| # | Task | Playbook path | What the check verifies | Check file |
|---|---|---|---|---|
| q5 | Write a playbook that installs `vim`, `wget`, `git` on webservers using `loop` + `when: distribution in ["Ubuntu", "Debian"]` | `workspace/loop_when.yml` | `loop:` present · `when:` present · `distribution` referenced · `vim`, `wget`, `git` installed on web1 | `q5_check.sh` |

---

### q6 — Handlers with `notify` · `button`

| # | Task | Playbook path | What the check verifies | Check file |
|---|---|---|---|---|
| q6 | Copy `/tmp/notify_src.txt` to `/tmp/handler_dest.txt` on webservers with `notify: write_log`; handler writes to `/tmp/handler.log` | `workspace/handler_demo.yml` | `notify:` present · `handlers:` section present · `copy:` used · `/tmp/handler_dest.txt` exists on web1 · `/tmp/handler.log` exists on web1 | `q6_check.sh` |

> Setup creates `/tmp/notify_src.txt` inside the container. The check resets artifacts before running to guarantee the handler fires.

---

### q7 — `force_handlers` · `button`

| # | Task | Playbook path | What the check verifies | Check file |
|---|---|---|---|---|
| q7 | Write a playbook with `force_handlers: yes`, two tasks (one succeeds with `notify`, one fails), and a handler that writes `/tmp/handler_forced.log` | `workspace/force_handler.yml` | `force_handlers: yes` present · `notify:` present · `handlers:` present · `/tmp/handler_forced.log` exists on web1 after playbook run | `q7_check.sh` |

> Setup creates `/tmp/force_src.txt`. The check resets artifacts and runs the playbook (ignoring exit code) before verifying the handler's log file.

---

### q8 — `failed_when` · `button`

| # | Task | Playbook path | What the check verifies | Check file |
|---|---|---|---|---|
| q8 | Run `echo "this task has failed"`, register output, use `failed_when` when `failed` appears in stdout, `ignore_errors: yes`, then show a debug task | `workspace/failed_when.yml` | `register:` present · `failed_when:` present · `ignore_errors:` present · `debug:` present · syntax OK · playbook exits 0 | `q8_check.sh` |

---

### q9 — `block / rescue / always` · `button`

| # | Task | Playbook path | What the check verifies | Check file |
|---|---|---|---|---|
| q9 | Write a playbook with `block` (reads nonexistent file → fails), `rescue` (creates `/tmp/rescue_output.txt`), `always` (debug message) | `workspace/block_rescue.yml` | `block:`, `rescue:`, `always:` all present · targets `webservers` · syntax OK · `/tmp/rescue_output.txt` contains `rescued` on web1 | `q9_check.sh` |

---

### q10 — `fail` Module with `when` · `button`

| # | Task | Playbook path | What the check verifies | Check file |
|---|---|---|---|---|
| q10 | Write a playbook with `fail: msg:` triggered by `when: distribution != required_os`, and a debug task on success | `workspace/fail_demo.yml` | `fail:` module present · `msg:` in fail task · `when:` present · `distribution` referenced · `debug:` present · syntax OK · runs OK on Ubuntu hosts | `q10_check.sh` |

---

## Summary

| Category | Questions | Count |
|---|---|---|
| Loops | q1 (simple), q2 (multivalued vars file), q5 (loop + when) | 3 |
| Conditionals | q3 (os_family), q4 (register + when) | 2 |
| Handlers | q6 (notify), q7 (force_handlers) | 2 |
| Error Handling | q8 (failed_when), q9 (block/rescue/always), q10 (fail module) | 3 |
| **Total** | q1–q10 | **10** |

## Topics covered (Chapter 7)

| Ansible feature | Question(s) |
|---|---|
| `loop` + `{{ item }}` | q1, q2, q5 |
| `vars_files` + multivalued loop | q2 |
| `when` + facts | q3, q4, q5, q10 |
| `register` | q4, q8 |
| `ignore_errors` | q4, q8 |
| `notify` + `handlers` | q6, q7 |
| `force_handlers` | q7 |
| `failed_when` | q8 |
| `block / rescue / always` | q9 |
| `fail` module | q10 |
