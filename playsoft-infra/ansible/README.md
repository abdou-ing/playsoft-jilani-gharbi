# Ansible — Playsoft Infrastructure

Automates provisioning of exam lab environments on top of Proxmox and a Kubernetes cluster (Hetzner). A single run of `site.yml` bootstraps the K8s cluster, configures VM access (VNC / SSH / RDP), registers connections in Apache Guacamole, and prints ready-to-use participant URLs.

---

> **Before you start — required setup**
>
> **1. Adapt all file paths**
> Every path referencing the project directory must match your local setup. Search for `<YOUR_PROJECT_PATH>` across all files and replace it with your actual absolute path:
> ```
> # Example
> /home/<YOUR_USER>/<YOUR_PROJECT_PATH>/playsoft-infra/terraform-k8s/tf_output.json
> ```
> Files that contain hardcoded paths and must be updated:
> - `group_vars/proxmox.yml` → `tf_output_path`
> - `roles/guacamole_connection/defaults/main.yml` → `tf_output_path_root`
> - `roles/guacamole_url/defaults/main.yml` → `tf_output_path_root`
> - `roles/win_setup/defaults/main.yml` → `tf_output_path`
> - `site.yml` → bootstrap lookup path
> - `cleanup_ssh.yml`, `cleanup_vnc.yml`, `cleanup_win.yml` → lookup path
>
> **2. Set your SSH private key**
> All inventory entries use `ansible_ssh_private_key_file`. Replace `<YOUR_SSH_KEY>` with the absolute path to your private key:
> ```ini
> ansible_ssh_private_key_file=/home/<YOUR_USER>/.ssh/<YOUR_KEY>
> ```
> This applies to: `inventory.ini` (proxmox, nat, masters, workers entries) and `inventory-exam.ini`.
>
> **3. Install requirements**
> ```bash
> # Install the required Ansible collection (Guacamole API)
> ansible-galaxy collection install scicore.guacamole
>
> # Install Python dependencies (if needed)
> pip install requests
> ```

---

## Directory Structure

```
ansible/
├── ansible.cfg                  # Global Ansible configuration
├── inventory.ini                # Main inventory (Proxmox, NAT, K8s nodes)
├── site.yml                     # Master playbook — full provisioning
├── cleanup_ssh.yml              # Remove SSH NAT iptables rules
├── cleanup_vnc.yml              # Remove VNC args and iptables rules
├── cleanup_win.yml              # Remove Windows RDP NAT iptables rules
├── vars.yml                     # Legacy / manual vars (sample users)
├── group_vars/
│   ├── all.yml                  # Shared variables for every host
│   ├── bastion.yml              # Variables for the [bastion] group
│   └── proxmox.yml              # Variables for the [proxmox] group
└── roles/
    ├── common/                  # K8s common node setup
    ├── master/                  # K8s master init + Guacamole manifests
    ├── worker/                  # K8s worker join
    ├── clone-repo-guacamole/    # Clone repo and apply K8s manifests
    ├── ssh_setup/               # SSH NAT forwarding on Proxmox
    ├── vnc_setup/               # VNC display setup on Proxmox VMs
    ├── win_setup/               # Windows RDP NAT on Proxmox
    ├── guacamole_connection/    # Create Guacamole connections + users via API
    └── guacamole_url/           # Generate and print direct Guacamole URLs
```

---

## Inventory

### `inventory.ini` — Main inventory

| Group | Host | Address |
|---|---|---|
| `proxmox` | `playsoft-proxmox` | `<PROXMOX_PUBLIC_IP>` |
| `nat` | `nat-server` | `<NAT_PUBLIC_IP>` |
| `masters` | `k8s-master` | `<K8S_MASTER_PRIVATE_IP>` (via NAT) |
| `workers` | `k8s-worker-1` | `<K8S_WORKER_PRIVATE_IP>` (via NAT) |
| `k8s_nodes` | `masters` + `workers` | Children group |

K8s nodes are reached through the NAT server using `ProxyCommand`.

---

## Configuration — `ansible.cfg`

| Setting | Value |
|---|---|
| Default inventory | `inventory.ini` |
| Remote user | `root` |
| Host key checking | Disabled |
| SSH timeout | 30 s |
| Output format | YAML (via `result_format`) |
| SSH pipelining | Enabled |
| Python interpreter | `auto_silent` |

---

## Variables

### `group_vars/all.yml` — Global defaults

| Variable | Default | Description |
|---|---|---|
| `guac_route` | `guacamole` | Guacamole nginx route name |
| `auth_username` / `auth_password` | `<GUAC_ADMIN_USER>` / `<GUAC_ADMIN_PASSWORD>` | Guacamole admin credentials |
| `user_prefix` | `<USER_PREFIX>` | Prefix for generated usernames |
| `user_password_prefix` | `<USER_PASSWORD_PREFIX>` | Prefix for generated passwords |
| `user_organization` | `<ORGANIZATION>` | Guacamole user organization |
| `user_email_domain` | `example.com` | Email domain for generated users |
| `connection_prefix` | `rhce-lab` | Prefix for Guacamole connection names |
| `vnc_hostname` | `<PROXMOX_PUBLIC_IP>` | Proxmox host exposed to Guacamole |
| `vnc_base_port` | `5915` | Base VNC port (`5915 + index`) |
| `win_rdp_base_port` | `3310` | Base RDP port (`3310 + index`) |
| `ssh_base_port` | `4000` | Base SSH NAT port (`4000 + (vmid - 200)`) |
| `ssh_user` / `ssh_password` | `<SSH_USER>` / `<SSH_PASSWORD>` | SSH credentials embedded in Guacamole |
| `win_user` / `win_password` | `<WIN_USER>` / `<WIN_PASSWORD>` | Windows credentials |
| `connection_type` | `["ssh"]` | Active protocols — toggle `vnc`, `ssh`, `win` |
| `exam_node_prefix` | `exam-rhce-node` | Label prefix for Guacamole connection names |

### `group_vars/proxmox.yml`

| Variable | Description |
|---|---|
| `start_vnc_port` | Computed start of VNC scan range |
| `max_vnc_port` | Computed end of VNC scan range |
| `node_name` | Proxmox node name |
| `tf_output_path` | Path to `tf_output.json` on the Proxmox host |

### `group_vars/bastion.yml`

| Variable | Value |
|---|---|
| `nginx_conf` | `/etc/nginx/sites-available/guacamole` |
| `private_server` | `<BASTION_PRIVATE_IP>` |

---

## Playbooks

### `site.yml` — Master provisioning playbook

Runs in sequential stages, each independently tagged:

| Stage | Tag | Hosts | What it does |
|---|---|---|---|
| 0 | _(bootstrap)_ | `all` | Loads `bastion_public_ip` from `tf_output.json` |
| 1 | `k8s_cluster` | `k8s_nodes` | Runs `common`, `master`, `worker`, `clone-repo-guacamole` roles, then waits 120 s for cluster stability |
| 2 | `access_setup` | `proxmox` | Conditionally runs `vnc_setup`, `ssh_setup`, or `win_setup` based on `connection_type` |
| 3 | `guacamole_connection` | `localhost` | Registers connections + users in Guacamole |
| 4 | `guacamole_url` | `localhost` | Runs `token-url.sh` and prints direct Guacamole access URLs |

Run specific stages with `--tags`:

```bash
ansible-playbook site.yml --tags access_setup
ansible-playbook site.yml --tags guacamole_connection,guacamole_url
```

---

### Cleanup Playbooks

All cleanup playbooks read `tf_output.json` to know which VMs to target, then remove the iptables rules (and VNC args) added during provisioning.

| Playbook | What it removes |
|---|---|
| `cleanup_ssh.yml` | NAT PREROUTING + FORWARD rules for SSH (ports `4000+`) |
| `cleanup_vnc.yml` | VNC `-args` from VM configs via `qm set --delete args` + INPUT rules |
| `cleanup_win.yml` | NAT PREROUTING + FORWARD rules for RDP (ports `3310+`) |

---

## Roles

### `common`

Ensures `containerd` is enabled and started on all K8s nodes. Applied to the `k8s_nodes` group.

---

### `master`

Bootstraps the K8s control plane:

1. Runs `kubeadm init --pod-network-cidr=192.168.0.0/16`
2. Copies `admin.conf` to `/root/.kube/config`
3. Installs **Calico CNI** from the official manifest
4. Generates and shares the `kubeadm join` token as a host fact

---

### `worker`

Joins the K8s cluster using the join command shared by the `master` role via host facts.

---

### `clone-repo-guacamole`

After the master is ready:

1. Creates `/guacamole/` directory
2. Clones the project repository into `/guacamole/playsoft-jilani-gharbi`
3. Applies K8s manifests from `guacamole-manifest/` in the `guacamole` namespace

---

### `ssh_setup`

Reads `tf_output.json` for SSH VM IDs and IPs, then for each VM:

- Adds a **NAT PREROUTING** rule: `<ssh_base_port + (vmid - 400)>` → `<vm_ip>:22`
- Adds a **FORWARD** rule: accept TCP to `<vm_ip>:22`

Port formula: `vmid 401 → port 4001`, `vmid 402 → port 4002`, etc.

---

### `vnc_setup`

Reads `tf_output.json` for VNC VM IDs, then for each VM:

1. Uploads `find_free_vnc.sh` to `/usr/local/bin/` on Proxmox
2. Calculates a deterministic VNC display and TCP port based on VMID
3. Sets VNC args on the VM via `qm set <vmid> -args "-vnc 0.0.0.0:<display>"`
4. Opens the firewall port via iptables INPUT rule
5. Restarts the VM (`qm stop && qm start`) to apply the change

`find_free_vnc.sh` scans a port range with `ss -tulpn` and returns the first free VNC display number.

---

### `win_setup`

Reads `tf_output.json` for Windows VM IDs and IPs, then for each VM:

1. Connects via **Evil-WinRM** and runs PowerShell to:
   - Set the network profile to **Private**
   - Create a Windows Firewall rule allowing TCP 3389 inbound
2. Adds a **NAT PREROUTING** rule: `<win_rdp_base_port + index>` → `<vm_ip>:3389`
3. Adds a **FORWARD** rule: accept TCP to `<vm_ip>:3389`

Retries the WinRM connection up to 10 times (30 s delay) to handle slow VM boot.

| Default | Value |
|---|---|
| `win_rdp_base_port` | `3301` |
| `win_network_interface_alias` | `Ethernet` |
| `win_firewall_rule_name` | `RDP from Proxmox` |
| `win_setup_retries` | `10` |
| `win_setup_delay` | `30 s` |

---

### `guacamole_connection`

Dynamically builds and registers all Guacamole resources from `tf_output.json`:

**Connection building** (based on `connection_type`):

| Type | Protocol | Port formula |
|---|---|---|
| `vnc` | VNC | `vnc_base_port + (vmid - 201)` |
| `ssh` | SSH | `ssh_base_port + (vmid - 400)` |
| `win` | RDP | `win_rdp_base_port + index` |

**User provisioning:**

- One Guacamole user per VM, named `<user_prefix>N` with password `<user_password_prefix>N`
- Each user is granted access only to their own connection(s)

Uses the `scicore.guacamole` Ansible collection to call the Guacamole REST API.

**Key defaults:**

| Variable | Default |
|---|---|
| `user_prefix` | `<USER_PREFIX>` |
| `user_password_prefix` | `<USER_PASSWORD_PREFIX>` |
| `connection_prefix` | `<CONNECTION_PREFIX>` |
| `vnc_base_port` | `5910` |
| `max_connections_per_user` | `2` |
| `ssh_user` / `ssh_password` | `<SSH_USER>` / `<SSH_PASSWORD>` |
| `win_user` / `win_password` | `<WIN_USER>` / `<WIN_PASSWORD>` |

---

### `guacamole_url`

Fetches a Guacamole auth token for each provisioned user via `POST /api/tokens` and prints the direct one-click URL:

```
http://<bastion_ip>/guacamole/#/?token=<authToken>
```

The user list is rebuilt from `tf_output.json` if not already populated.

---

## Dependencies

- **Ansible Collection:** `scicore.guacamole` (for `guacamole_connection` and `guacamole_url` roles)
- **Tool on Proxmox host:** `evil-winrm` (for `win_setup` role)
- **Terraform output file:** `terraform-k8s/tf_output.json` must exist before running any access-setup or cleanup playbook

### Required outputs in `tf_output.json`

| Key | Used by |
|---|---|
| `bastion_public_ip` | `site.yml` bootstrap, `guacamole_connection`, `guacamole_url` |
| `vnc_vm_ids` | `vnc_setup`, `guacamole_connection`, `cleanup_vnc` |
| `ssh_vm_ids` / `ssh_vm_ips` | `ssh_setup`, `guacamole_connection`, `cleanup_ssh` |
| `windows_vm_ids` / `windows_vm_ips` | `win_setup`, `guacamole_connection`, `cleanup_win` |

---

## Common Usage

```bash
# Full provisioning (K8s cluster + access + Guacamole)
ansible-playbook site.yml

# Only set up VM access and Guacamole (skip K8s cluster setup)
ansible-playbook site.yml --tags access_setup,guacamole_connection,guacamole_url

# Only regenerate Guacamole URLs
ansible-playbook site.yml --tags guacamole_url

# Remove all SSH NAT rules
ansible-playbook cleanup_ssh.yml

# Remove all VNC configuration
ansible-playbook cleanup_vnc.yml

# Remove all Windows RDP NAT rules
ansible-playbook cleanup_win.yml
```

### Switching connection types

Edit `group_vars/all.yml` and uncomment the desired protocol(s):

```yaml
connection_type:
  - "ssh"   # Linux SSH access
# - "vnc"   # Linux VNC access
# - "win"   # Windows RDP access
```
