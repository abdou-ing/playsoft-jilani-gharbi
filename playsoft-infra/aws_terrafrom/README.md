# K8s on AWS — Terraform (VPC + Network + ASGs + ALB + IAM)

Self-managed Kubernetes: **1 master + 3 workers** under ASGs, in **private subnets**,
with an **ALB** for app ingress and a **stable ENI** as the control-plane endpoint
(no NLB). A public **Bastion host** doubles as the SSH jump box and the Ansible
runner that joins/removes nodes on a cron.

Modular layout (mirrors `terraform-hzn`): a thin root wires together
self-contained per-concern modules under `modules/`, instead of one flat
directory of `.tf` files.

## Files

| File | What it creates |
|------|-----------------|
| `versions.tf` | Provider + version pins, default tags |
| `variables.tf` | All inputs |
| `main.tf` | Wires the 5 modules together + the master<-worker security group rules |
| `outputs.tf` | Key IDs / endpoints, forwarded from module outputs |
| `terraform.tfvars.example` | Example values to copy to `terraform.tfvars` |

## Modules

| Module | What it creates |
|--------|-----------------|
| `modules/network` | VPC, public/private subnets (3 AZ), IGW, 1 NAT, route tables |
| `modules/load-balancer` | ALB security group, public ALB, target group (worker NodePort), :80 listener |
| `modules/bastion` | Bastion instance role + profile, its security group (SSH from `admin_cidr` only), the bastion EC2 in a **public** subnet + an EIP |
| `modules/k8s-master` | Stable master ENI, master instance role + profile, master security group (self-only rules), master launch template + userdata, master ASG (pinned, size 1) |
| `modules/k8s-worker` | Worker instance role + profile, worker security group, worker launch template + userdata, worker ASG (min/max/desired, spans all AZs) |

`modules/k8s-master` and `modules/k8s-worker` each carry their own `userdata/`
script and their own Ubuntu AMI lookup (`data.tf`) — this mirrors
`terraform-hzn`'s convention of each server-role module owning its own image
data source rather than sharing one from the root.

## The bastion: one box, two roles

There is no separate private-subnet Ansible node. The bastion serves both:

1. **SSH jump box** — your entry point into the private cluster
2. **Ansible runner** — discovers nodes and runs the join/cleanup playbooks

It sits in a **public** subnet with an EIP (not `private[0]` like the other
node roles), since it needs to be internet-reachable to act as the jump box.
Being on the network edge also gives it direct private-IP reachability to the
master/workers for Ansible.

```
Public subnet + EIP
  └─ Bastion EC2 (SSH jump + Ansible runner)
     inbound: SSH from admin_cidr only
     outbound: reaches master/workers over their private IPs in the same VPC
```

SSH in with **agent forwarding** so cluster keys are never stored on the bastion:

```bash
ssh -A ubuntu@$(terraform output -raw bastion_public_ip)
```

SSM Session Manager is also enabled as a keyless fallback.

**Lock down `admin_cidr`.** A public SSH box open to `0.0.0.0/0` is the
biggest risk in this layout — restrict it to your IP as `x.x.x.x/32`. There's
no default for `admin_cidr`; you must set it explicitly.

## Where YOUR master/worker scripts go

- `modules/k8s-master/userdata/master.sh`
- `modules/k8s-worker/userdata/worker.sh`

Terraform passes these template vars into `master.sh`:

- `${eni_id}` — the stable ENI to attach on boot (device-index 1)
- `${master_endpoint}` — the fixed IP for `--control-plane-endpoint`
- `${region}`, `${cluster_name}`

`worker.sh` gets `${master_endpoint}`, `${region}`, `${cluster_name}`.

Because these files run through `templatefile()`, **escape literal shell
variables as `$${VAR}`** (Terraform vars stay `${...}`) — this includes
inside comments, since `templatefile()` parses the whole file.

## Apply

```bash
cp terraform.tfvars.example terraform.tfvars   # edit values, especially admin_cidr
terraform init
terraform plan
terraform apply
```

## Key design notes

- **Master ASG is pinned to `private[0]`** — the ENI is AZ-locked to that subnet.
  Do not spread the master across AZs.
- **Worker ASG spans all AZs** and auto-registers with the ALB target group.
- **Bastion is pinned to `public[0]`** and gets an EIP — it's the only node
  role that's internet-reachable.
- **Master <-> worker security group rules are split across two places**:
  the rules a role's own security group needs from another role that's
  already created (e.g. worker's SG allowing from master's SG, since
  `k8s-master` is created first) live inside that role's module; the rules
  that would require a module to depend on another module that in turn
  depends on it (master's SG allowing from worker's SG) live as standalone
  `aws_security_group_rule` resources in the root `main.tf`, added after both
  modules exist.
- **Single NAT gateway** to save cost; for production use one NAT per AZ.
- **SSM Session Manager** is enabled on all nodes (`AmazonSSMManagedInstanceCore`),
  so you can reach private instances without SSH keys even without the bastion.
- **No S3/KMS** per your setup — so make sure the master keeps `/var/lib/etcd`
  on an EBS volume that survives replacement (add a block device / mount in your
  master script), since there are no etcd snapshots to S3.

## Not included here (next steps)

- The Ansible `aws_ec2.yml` inventory + `site.yml` playbook + cron
- The baked AMI build
- HTTPS listener (needs an ACM cert — commented stub in `modules/load-balancer/main.tf`)
