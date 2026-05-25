# Scenario-Based Questions — Question Bank

This folder contains **7 questions** (q78–q84) built around a single narrative:

> **"Onboarding John to the Dev Team"** — A junior developer joins today. You work through user creation, group membership, sudo access, password policy, shared directory setup, and contract expiry — step by step, as a real sysadmin would.

The questions are designed to be **independent**: each setup script resets its own state and injects any prerequisite it needs, so skipping a question never blocks a later one.

---

## Question Types

| Type | How it works | Graded by |
|---|---|---|
| `multi` | 4-choice MCQ, one correct answer, answers are shuffled | Student selects an answer |
| `button` | Hands-on task — student performs it in the terminal, then clicks **Check** | `_check.sh` script verifies the result |

---

## Question Index

### q78 — `button` — Create User

| # | Task | What the check verifies | Check file |
|---|---|---|---|
| q78 | Create user `john` with home directory `/home/john` and shell `/bin/bash` | User exists · shell is `/bin/bash` · home dir `/home/john` exists on disk | `q78_check.sh` |

> Setup wipes john's account clean each run so re-attempts start fresh.

---

### q79 — `button` — Group Membership

| # | Task | What the check verifies | Check file |
|---|---|---|---|
| q79 | Add `john` to the `developers` secondary group | `developers` group exists · john is a member | `q79_check.sh` |

> Setup creates `developers` group if missing and ensures john exists (skip-q78 guard). Removes john from `developers` each run for a clean task.

---

### q80 — `button` — Sudo Access

| # | Task | What the check verifies | Check file |
|---|---|---|---|
| q80 | Grant john sudo privileges by adding him to the `sudo` group (Ubuntu) | john is a member of the `sudo` group | `q80_check.sh` |

> Setup ensures john exists (skip-q78 guard) and removes him from `sudo` each run for a clean task.

---

### q81 — `multi` — Password Aging Audit

| # | Topic | Candidate command |
|---|---|---|
| q81 | Read John's current maximum password age before any policy is applied | `chage -l john` |

> Setup ensures john exists (skip-q78 guard) and resets chage to Ubuntu defaults (`99999`) so the MCQ always reflects the pre-policy state, even if q82 was attempted first.

---

### q82 — `button` — Password Policy

| # | Task | What the check verifies | Check file |
|---|---|---|---|
| q82 | Set John's password to expire every `90` days with a `7`-day warning | `chage -l john` → Max: 90 · Warn: 7 | `q82_check.sh` |

> Setup ensures john exists (skip-q78 guard) and resets chage to defaults each run.

---

### q83 — `button` — Setgid Directory

| # | Task | What the check verifies | Check file |
|---|---|---|---|
| q83 | Create `/srv/devproject` owned by `developers` with the setgid bit set | Directory exists · group owner is `developers` · setgid bit is set | `q83_check.sh` |

> Fully independent — does not depend on the john user. Setup creates the `developers` group if missing and removes `/srv/devproject` each run for a clean task.

---

### q84 — `button` — Account Expiry

| # | Task | What the check verifies | Check file |
|---|---|---|---|
| q84 | Set John's account to expire on `2026-12-31` | `chage -l john` → Account expires: Dec 31, 2026 | `q84_check.sh` |

> Setup ensures john exists (skip-q78 guard) and resets account expiry to "never" each run.

---

## Dependency map

```
q78  — fully independent (clean state: john deleted each run)
q79  — skip-q78 guard: creates john if q78 was skipped
q80  — skip-q78 guard: creates john if q78 was skipped
q81  — skip-q78 guard: creates john if q78 was skipped; resets chage if q82 was done first
q82  — skip-q78 guard: creates john if q78 was skipped
q83  — fully independent (does not depend on john)
q84  — skip-q78 guard: creates john if q78 was skipped
```

Every setup script handles its own prerequisites — no question is ever blocked by a skipped predecessor.

---

## Summary

| Category | Questions | Count |
|---|---|---|
| MCQ (`multi`) | q81 | 1 |
| Hands-on (`button`) | q78, q79, q80, q82, q83, q84 | 6 |
| **Total** | q78–q84 | **7** |
