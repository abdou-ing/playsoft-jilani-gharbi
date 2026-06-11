# AlmaLinux 9 Proxmox Template — Packer Build

Builds a Proxmox VM template running AlmaLinux 9 with a full GUI (GNOME), pre-configured users, and tooling ready for lab provisioning.

## Prerequisites

- Proxmox node with a running web server (to serve the kickstart file)
- AlmaLinux 9 DVD ISO uploaded to Proxmox storage (`local:iso/AlmaLinux-9.7-x86_64-dvd.iso`)
- Packer installed on the machine running the build

## Setup

**1. Serve the kickstart file from the Proxmox node**

Copy `files/kickstart/ks.cfg` to the root of the web server on the Proxmox node so it is reachable at:

```
http://<proxmox_ip>/ks.cfg
```

**2. Provide sensitive variables**

Sensitive values must be passed at build time or via environment variable:

| Variable | Description |
|---|---|
| `proxmox_api_token_secret` | Proxmox API token secret for the `root@pam!packer` token |
| `candidate_lab_user_password` | Password for the candidate lab user (`student`) — min 10 chars. Can also be set via `INSTALAB_USER_PASS` env var |
| `vm_root_pw` | Root password for the VM |

Non-sensitive defaults are in `variables.auto.pkrvars.hcl` and can be overridden with `-var`.

## Build

The VM ID is dynamically allocated — do not hardcode it. Fetch a free VM ID from Proxmox before running the build:

```bash
vm_id=$(ssh proxmox_server "sudo bash /opt/get-proxmox-template-id.sh")

packer build -var vm_id=$vm_id  -var env=dev|stg|prd -var version=9|10 -var candidate_lab_user_password=<password> -var proxmox_api_token_secret=<token>  .
```

## What the build produces

- AlmaLinux 9 template (`TPL-Lab-AlmaLinux9`) with a **dynamically assigned VM ID** (fetched via `/opt/get-proxmox-template-id.sh`)
- GNOME desktop with GDM enabled
- `student` user (candidate) with GUI access 
- `svcuseran` user (management) with passwordless sudo and SSH key pre-installed
- YARA 4.2.3 compiled and installed
- auditd enabled
- US keyboard layout forced (prevents Guacamole key-mapping issues)
