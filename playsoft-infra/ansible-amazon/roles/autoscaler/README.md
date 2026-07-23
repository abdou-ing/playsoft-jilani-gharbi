# roles/autoscaler — CPU-based worker autoscaling on AWS

Port of the Hetzner project's autoscaler (`playsoft-infra/ansible/roles/autoscaler`
+ `playsoft-infra/prometheus/webhook/webhook.py`) — same shape, ported to AWS's
APIs, not a re-architecture. Read `../../prometheus/AUTOSCALER.md` first if
you haven't; the hardening it documents (cooldown mutex, no-timeout-on-apply,
rollback-excludes-by-name, `0644` `targets.json`, the static Grafana
Nodename variable) all applies here unchanged, since it's cloud-agnostic
Python/systemd, not Hetzner-API-specific.

**Opt-in, like `k8s_vault`** — never runs as part of a normal `site.yml`
pass. Run it explicitly:
```bash
ansible-playbook -i inventory/aws_ec2.yml site.yml --tags autoscaler,monitoring,prometheus,grafana
```

## What's different from the Hetzner version, and why

- **Two separate Terraform states, not one.** The floor worker lives in the
  main `aws_terrafrom` state; this role stages a second, empty-by-default
  Terraform root on the bastion (`files/terraform/`, own `for_each` over a
  `workers` map) that only ever contains autoscaler-created workers. This is
  what makes "scale-in can never remove the floor" a structural property of
  the state boundary, not application logic that has to get it right —
  exactly how Hetzner's `terraform-k8s` / `prometheus/terraform` split works.
- **Standalone join playbook (`files/join-worker.yml`), reusing real roles.**
  `site.yml --limit <new-worker>` doesn't work here: the `worker` role's join
  task reads a `kube_join_command` fact that's only set when the `master`
  play runs in the *same* invocation, and `--limit` excludes the master from
  every play. So this role's own master-token-generation is a lightweight
  two-task play (matching Hetzner's `join-worker.yml` shape exactly), but the
  worker side reuses `roles: [common, worker]` verbatim — not reimplemented.
  That also means it gets `roles/common`'s NAT-gateway-race-aware cloud-init
  wait for free, which is why `scale_out()` in `webhook.py` doesn't
  reimplement Hetzner's raw-SSH reboot-polling at all (AWS's `worker.sh`
  never reboots in the first place).
- **Target group deregistration happens *before* drain, not after.**
  Registration is Terraform-managed (`aws_lb_target_group_attachment`,
  created automatically as part of `apply_workers()`), but on scale-in,
  `webhook.py` explicitly calls `aws elbv2 deregister-targets` as the very
  first step — mirroring Hetzner's own "remove from Prometheus before drain"
  ordering, same reason: don't let a load balancer keep routing live traffic
  to a node whose pods are already being evicted.
- **No boto3.** `webhook.py` shells out to the `aws` CLI (installed by this
  role) instead, keeping the same "stdlib + one CLI, no third-party Python
  packages" footprint Hetzner's version has with the `hcloud` HTTP API.

## Required environment variables (control node, before running)

| Var | Purpose |
|---|---|
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | Becomes the bastion's own credentials for `aws` CLI + Terraform. No instance IAM role is possible in this account (`iam:CreateRole` isn't granted) — this is the accepted trade-off, same shape as Hetzner's `HCLOUD_TOKEN`. |
| `WEBHOOK_SHARED_SECRET` | Bearer-auth secret for the webhook (`openssl rand -hex 32`). Webhook refuses to start without it. |
| `SMTP_AUTH_PASSWORD` | Gmail app password for Alertmanager's email receiver (non-scaling alerts: `NodeDown`, CPU/memory/disk warnings). |

None of these are written to any file that gets committed — `no_log: true`
throughout, same as the Vault `secret_id` delivery.

## Real trade-off this introduces, on purpose, not by accident

The bastion (`aws_terrafrom/modules/bastion`) already has port 80 open to
`0.0.0.0/0` and runs nginx reverse-proxying public app traffic — it's not
just an admin-facing SSH box. Stacking this role's credentials (the SSH
private key, long-lived AWS keys, root `terraform apply`/`kubectl`/
`ansible-playbook`) onto an already-internet-facing instance means an
nginx/app-path compromise is one hop from full infra takeover. Accepted
here (matching Hetzner's own posture, which has the same shape), not solved
— worth sizing/monitoring the bastion instance with both roles' load in mind.

## Health checks

Same as Hetzner (`../../prometheus/AUTOSCALER.md` §6-7), on the bastion:
```bash
curl -i http://127.0.0.1:8080/healthz          # webhook, no auth needed
curl -i http://localhost:9093/-/healthy         # alertmanager
systemctl is-active alertmanager autoscaler
journalctl -u autoscaler -u alertmanager -f
```
