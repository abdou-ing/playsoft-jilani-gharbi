# Scenario-Based Questions — Question Bank

This folder contains **13 questions** across **two narrative scenarios**.
All questions follow the **RHCE pattern**: write an Ansible playbook on the control node that configures managed hosts (`web1`, `web2`, `bd1`). Each setup script resets its own state on the managed hosts, so skipping a question never blocks a later one.

**Control node:** Ubuntu 24.04 · runs as `ansible_user` · workspace at `/home/ansible_user/workspace/`
**Managed hosts:** `web1` (10.30.0.11) · `web2` (10.30.0.12) · `bd1` (10.30.0.13) · password `Labby123`

---

## Question Types

| Type | How it works | Graded by |
|---|---|---|
| `multi` | 4-choice MCQ, one correct answer, answers are shuffled | Student selects an answer |
| `button` | Hands-on task — student writes and runs an Ansible playbook, then clicks **Check** | `_check.sh` script verifies state on managed hosts via `ansible` ad-hoc commands |

---

# Scenario 1 — "Provisioning the Dev Team via Ansible" (q78–q83)

The operations team needs to onboard a new developer named `john` on all webservers. You write Ansible playbooks on the control node to create the user, configure group membership, deploy sudo privileges, enforce password policy, create a shared directory, and set an account expiry — as a real RHCE candidate would.

**Ansible modules covered:** `ansible.builtin.user`, `ansible.builtin.group`, `ansible.builtin.copy`, `ansible.builtin.command` (chage), `ansible.builtin.file`

---

## Q78 — `button` — Create User with Ansible

| Field | Value |
|---|---|
| Task | Write a playbook at `/home/ansible_user/workspace/onboard_john.yml` that creates user `john` on all `webservers` with home directory and `/bin/bash` shell |
| Ansible module | `ansible.builtin.user` |
| Check verifies | User exists on web1 · shell is `/bin/bash` · `/home/john` exists |
| Check file | `q78_check.sh` |
| State reset | `john` is deleted from webservers (`state: absent, remove: yes`) at setup |
| Independent | Yes — no prerequisites |

---

## Q79 — `button` — Group Membership via Ansible

| Field | Value |
|---|---|
| Task | Write a playbook at `/home/ansible_user/workspace/dev_group.yml` that creates the `developers` group and adds `john` to it (as secondary group) on all `webservers` |
| Ansible modules | `ansible.builtin.group` + `ansible.builtin.user` with `append: yes` |
| Check verifies | `developers` group exists on web1 · john is a member (via `id john`) |
| Check file | `q79_check.sh` |
| State reset | `developers` group removed + john's group membership cleared at setup |
| Skip guard | Creates john if q78 was skipped |

---

## Q80 — `button` — Sudo Access via Ansible copy

| Field | Value |
|---|---|
| Task | Write a playbook at `/home/ansible_user/workspace/sudo_access.yml` that deploys `/etc/sudoers.d/john` (content: `john ALL=(ALL) NOPASSWD:ALL`, mode `0440`) on all `webservers` using the `copy` module with sudoers validation |
| Ansible module | `ansible.builtin.copy` with `validate: /usr/sbin/visudo -cf %s` |
| Check verifies | `/etc/sudoers.d/john` exists on web1 · mode is `0440` · content grants NOPASSWD:ALL |
| Check file | `q80_check.sh` |
| State reset | `/etc/sudoers.d/john` deleted from webservers at setup |
| Skip guard | Creates john if q78 was skipped |

---

## Q81 — `button` — Password Policy via Ansible command

| Field | Value |
|---|---|
| Task | Write a playbook at `/home/ansible_user/workspace/password_policy.yml` that sets john's password to expire every `90` days with a `7`-day warning on all `webservers` using `chage` via the `command` module |
| Ansible module | `ansible.builtin.command` with `cmd: chage -M 90 -W 7 john` and `changed_when: true` |
| Check verifies | `chage -l john` on web1 shows max=90 days · warning=7 days |
| Check file | `q81_check.sh` |
| State reset | chage reset to defaults (`-M 99999 -W 7`) on webservers at setup |
| Skip guard | Creates john if q78 was skipped |

---

## Q82 — `button` — Setgid Shared Directory via Ansible file

| Field | Value |
|---|---|
| Task | Write a playbook at `/home/ansible_user/workspace/shared_dir.yml` that creates `/srv/devproject` on all `webservers` owned by the `developers` group with mode `02775` (setgid) |
| Ansible modules | `ansible.builtin.group` (create developers) + `ansible.builtin.file` with `mode: "02775"` |
| Check verifies | `/srv/devproject` exists on web1 · group is `developers` · setgid bit is set |
| Check file | `q82_check.sh` |
| State reset | `/srv/devproject` deleted from webservers at setup |
| Independent | Yes — no john dependency |

---

## Q83 — `button` — Account Expiry via Ansible command

| Field | Value |
|---|---|
| Task | Write a playbook at `/home/ansible_user/workspace/account_expiry.yml` that sets john's account to expire on `2026-12-31` on all `webservers` using `chage -E` via the `command` module |
| Ansible module | `ansible.builtin.command` with `cmd: chage -E 2026-12-31 john` and `changed_when: true` |
| Check verifies | `chage -l john` on web1 shows account expires in 2026 |
| Check file | `q83_check.sh` |
| State reset | Account expiry reset to "never" (`-E -1`) on webservers at setup |
| Skip guard | Creates john if q78 was skipped |

---

## Scenario 1 — Dependency Map

```
q78  ── fully independent (john deleted from webservers each run)
q79  ── skip-q78 guard: creates john on webservers if missing
q80  ── skip-q78 guard: creates john on webservers if missing
q81  ── skip-q78 guard: creates john on webservers if missing
q82  ── fully independent (no john dependency)
q83  ── skip-q78 guard: creates john on webservers if missing
```

## Scenario 1 — Summary

| # | Type | Topic | Playbook path |
|---|---|---|---|
| q78 | `button` | Create user john via Ansible | `onboard_john.yml` |
| q79 | `button` | Add john to developers group | `dev_group.yml` |
| q80 | `button` | Deploy sudoers file with copy + validate | `sudo_access.yml` |
| q81 | `button` | Set password expiry with chage via command | `password_policy.yml` |
| q82 | `button` | Create setgid shared directory | `shared_dir.yml` |
| q83 | `button` | Set account expiry with chage -E | `account_expiry.yml` |

---

# Scenario 2 — "Hardening the Web Servers via Ansible" (q84–q90)

The security team requires a series of hardening tasks on all webservers. You write Ansible playbooks to configure SSH, deploy banners, manage host resolution, tune kernel parameters, and apply firewall rules — targeting the managed hosts from the control node.

**Ansible modules covered:** `ansible.builtin.lineinfile`, `ansible.builtin.service`, `ansible.builtin.copy`, `ansible.builtin.command` (sysctl), `ansible.builtin.iptables`

---

## Q84 — `button` — SSH Hardening via Ansible lineinfile

| Field | Value |
|---|---|
| Task | Write a playbook at `/home/ansible_user/workspace/ssh_hardening.yml` that sets `PermitRootLogin no`, `PasswordAuthentication no`, `ClientAliveInterval 300` in `/etc/ssh/sshd_config` and restarts SSH on all `webservers` |
| Ansible modules | `ansible.builtin.lineinfile` (×3) + `ansible.builtin.service` |
| Check verifies | `sshd -T` on web1 shows all three directives correctly set |
| Check file | `q84_check.sh` |
| State reset | SSH restored to permissive defaults + service restarted at setup |
| Independent | Yes |

---

## Q85 — `button` — SSH Login Banner via Ansible

| Field | Value |
|---|---|
| Task | Write a playbook at `/home/ansible_user/workspace/ssh_banner.yml` that copies a local banner file to `/etc/ssh/banner`, sets `Banner /etc/ssh/banner` in `sshd_config`, and restarts SSH on all `webservers` |
| Ansible modules | `ansible.builtin.copy` + `ansible.builtin.lineinfile` + `ansible.builtin.service` |
| Banner source | `/home/ansible_user/workspace/motd_banner.txt` (created by setup script) |
| Check verifies | `/etc/ssh/banner` exists on web1 · `sshd -T` shows `banner /etc/ssh/banner` |
| Check file | `q85_check.sh` |
| State reset | `/etc/ssh/banner` deleted + Banner directive removed + service restarted at setup |
| Independent | Yes |

---

## Q86 — `button` — /etc/hosts Entries via Ansible lineinfile

| Field | Value |
|---|---|
| Task | Write a playbook at `/home/ansible_user/workspace/hosts_entries.yml` that adds `10.30.0.11 web1`, `10.30.0.12 web2`, `10.30.0.13 bd1` to `/etc/hosts` on `all` managed hosts using `lineinfile` |
| Ansible module | `ansible.builtin.lineinfile` with `state: present` (one task per entry) |
| Check verifies | All three entries exist in `/etc/hosts` on web1 |
| Check file | `q86_check.sh` |
| State reset | All three entries removed from `/etc/hosts` on managed hosts at setup |
| Independent | Yes |

---

## Q87 — `multi` — Which module manages services?

| Field | Value |
|---|---|
| Question | Which Ansible module manages service state (started/stopped/restarted) and boot enablement across Linux init systems without needing to know if it's systemd or SysV? |
| Correct answer | `ansible.builtin.service` |
| Wrong answers | `ansible.builtin.systemd`, `ansible.builtin.command`, `ansible.builtin.daemon` |
| Candidate command | `ansible-doc ansible.builtin.service \| grep -A5 'state:'` |
| Independent | Yes — MCQ, no state changes |

---

## Q88 — `button` — NTP Configuration via Ansible

| Field | Value |
|---|---|
| Task | Write a playbook at `/home/ansible_user/workspace/ntp_config.yml` that sets `NTP=pool.ntp.org` in `/etc/systemd/timesyncd.conf` and restarts + enables `systemd-timesyncd` on all `webservers` |
| Ansible modules | `ansible.builtin.lineinfile` + `ansible.builtin.service` |
| Check verifies | `grep '^NTP=' /etc/systemd/timesyncd.conf` on web1 returns `pool.ntp.org` |
| Check file | `q88_check.sh` |
| State reset | NTP= line removed + service restarted at setup |
| Independent | Yes |

---

## Q89 — `button` — IP Forwarding via Ansible

| Field | Value |
|---|---|
| Task | Write a playbook at `/home/ansible_user/workspace/ip_forwarding.yml` that creates `/etc/sysctl.d/99-forwarding.conf` with `net.ipv4.ip_forward = 1` using `lineinfile` (with `create: yes`) and applies it with `sysctl -p` on all `webservers` |
| Ansible modules | `ansible.builtin.lineinfile` (create: yes) + `ansible.builtin.command` (sysctl -p) |
| Check verifies | File exists on web1 · `sysctl net.ipv4.ip_forward` returns `1` |
| Check file | `q89_check.sh` |
| State reset | Config file deleted + `ip_forward` set to `0` on webservers at setup |
| Independent | Yes |

---

## Q90 — `button` — Firewall Rules via Ansible iptables

| Field | Value |
|---|---|
| Task | Write a playbook at `/home/ansible_user/workspace/firewall_rules.yml` that applies iptables rules on all `webservers`: accept established/related, accept TCP 22 and TCP 80, reject everything else in INPUT |
| Ansible module | `ansible.builtin.iptables` (one task per rule, REJECT last) |
| Check verifies | `iptables -L INPUT -n` on web1 shows ACCEPT for port 22, ACCEPT for port 80, and a REJECT rule |
| Check file | `q90_check.sh` |
| State reset | INPUT chain flushed (`iptables -F INPUT`) on webservers at setup |
| Independent | Yes |

---

## Scenario 2 — Dependency Map

```
q84  ── fully independent (SSH defaults restored each run)
q85  ── fully independent (banner removed each run)
q86  ── fully independent (/etc/hosts entries removed each run)
q87  ── MCQ, fully independent
q88  ── fully independent (NTP line removed each run)
q89  ── fully independent (config deleted + kernel reset each run)
q90  ── fully independent (INPUT chain flushed each run)
```

All 7 hardening questions are self-contained — no question depends on another.

## Scenario 2 — Summary

| # | Type | Topic | Playbook path |
|---|---|---|---|
| q84 | `button` | SSH hardening (3 directives + service restart) | `ssh_hardening.yml` |
| q85 | `button` | Deploy SSH login banner | `ssh_banner.yml` |
| q86 | `button` | Add /etc/hosts entries on all hosts | `hosts_entries.yml` |
| q87 | `multi` | Which module manages services? | — |
| q88 | `button` | Configure NTP with timesyncd | `ntp_config.yml` |
| q89 | `button` | Enable IP forwarding via sysctl | `ip_forwarding.yml` |
| q90 | `button` | Apply iptables firewall rules | `firewall_rules.yml` |

---

# Full Question Index

| # | Scenario | Type | Topic |
|---|---|---|---|
| q78 | Provisioning the Dev Team | `button` | Create user john on webservers |
| q79 | Provisioning the Dev Team | `button` | Add john to developers group |
| q80 | Provisioning the Dev Team | `button` | Deploy sudoers file (copy + validate) |
| q81 | Provisioning the Dev Team | `button` | Set password expiry with chage via command |
| q82 | Provisioning the Dev Team | `button` | Create setgid shared directory |
| q83 | Provisioning the Dev Team | `button` | Set account expiry date |
| q84 | Hardening the Web Servers | `button` | SSH hardening with lineinfile |
| q85 | Hardening the Web Servers | `button` | SSH login banner (copy + lineinfile) |
| q86 | Hardening the Web Servers | `button` | /etc/hosts entries on all managed hosts |
| q87 | Hardening the Web Servers | `multi` | Which module manages services? |
| q88 | Hardening the Web Servers | `button` | NTP configuration (timesyncd) |
| q89 | Hardening the Web Servers | `button` | IP forwarding via sysctl |
| q90 | Hardening the Web Servers | `button` | iptables firewall rules |

**Total: 13 questions · 1 multi · 12 button · 2 scenarios**
