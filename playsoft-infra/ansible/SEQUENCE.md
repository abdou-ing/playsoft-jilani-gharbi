# Sequence Diagram — Global Ansible Flow

```mermaid
%%{init: {'theme': 'default', 'themeVariables': {'background': '#ffffff', 'mainBkg': '#ffffff', 'textColor': '#000000', 'actorTextColor': '#000000', 'actorBkg': '#f5f5f5', 'actorBorderColor': '#333333', 'signalColor': '#333333', 'signalTextColor': '#000000', 'noteTextColor': '#000000', 'noteBkgColor': '#ffffcc', 'noteBorderColor': '#333333', 'loopTextColor': '#000000', 'activationBorderColor': '#333333', 'activationBkgColor': '#e8e8e8', 'sequenceNumberColor': '#ffffff'}}}%%
sequenceDiagram
    autonumber
    participant Op as Lab Admin<br/>(local machine)
    participant AC as Ansible Controller<br/>(localhost)
    participant TF as tf_output.json
    participant NAT as NAT Server
    participant Master as K8s Master
    participant Worker as K8s Worker
    participant PVE as Proxmox Host
    participant GUAC as Guacamole API

    Op->>AC: ansible-playbook site.yml

    %% ── Stage 0 : Bootstrap ─────────────────────────────────────
    rect rgb(230, 240, 255)
        Note over AC,TF: Stage 0 — Bootstrap
        AC->>TF: lookup tf_output.json
        TF-->>AC: bastion_public_ip
    end

    %% ── Stage 1 : K8s Cluster ───────────────────────────────────
    rect rgb(230, 255, 230)
        Note over AC,Worker: Stage 1 — K8s Cluster [tag: k8s_cluster]

        AC->>NAT: ProxyCommand tunnel
        NAT-->>Master: forward SSH
        NAT-->>Worker: forward SSH

        AC->>Master: role/common — enable containerd
        AC->>Worker: role/common — enable containerd

        AC->>Master: role/master
        Master->>Master: kubeadm init (CIDR 192.168.0.0/16)
        Master->>Master: kubectl apply calico.yaml
        Master-->>AC: kube_join_command (host fact)

        AC->>Worker: role/worker
        Worker->>Master: kubeadm join

        AC->>Master: role/clone-repo-guacamole
        Master->>Master: git clone playsoft-jilani-gharbi (feature/terraform)
        Master->>Master: kubectl apply -n guacamole guacamole-manifest/

        AC->>AC: pause 120 s (cluster stabilise)
    end

    %% ── Stage 2 : Access Setup ──────────────────────────────────
    rect rgb(255, 245, 220)
        Note over AC,PVE: Stage 2 — Access Setup [tag: access_setup]
        AC->>TF: lookup tf_output.json
        TF-->>AC: vm_ids + vm_ips (ssh / vnc / windows)

        alt connection_type = ssh
            loop for each SSH VM
                AC->>PVE: iptables NAT PREROUTING<br/>port (4000 + vmid-400) → vm_ip:22
                AC->>PVE: iptables FORWARD ACCEPT → vm_ip:22
            end
        else connection_type = vnc
            AC->>PVE: upload find_free_vnc.sh
            loop for each VNC VM
                AC->>PVE: qm set vmid -args "-vnc 0.0.0.0:<display>"
                AC->>PVE: iptables INPUT ACCEPT port (5915 + index)
                AC->>PVE: qm stop && qm start vmid
            end
        else connection_type = win
            loop for each Windows VM
                AC->>PVE: evil-winrm → Set network Private<br/>+ enable RDP firewall rule
                AC->>PVE: iptables NAT PREROUTING<br/>port (3310 + index) → vm_ip:3389
                AC->>PVE: iptables FORWARD ACCEPT → vm_ip:3389
            end
        end
    end

    %% ── Stage 3 : Guacamole Connections ─────────────────────────
    rect rgb(255, 230, 230)
        Note over AC,GUAC: Stage 3 — Guacamole Provisioning [tag: guacamole_connection]
        AC->>TF: lookup tf_output.json
        TF-->>AC: vm_ids lists + bastion_public_ip

        AC->>AC: build guac_connections list<br/>(vnc / ssh / rdp per vm)
        AC->>AC: build guacamole_users list<br/>(<USER_PREFIX>N → own connection)

        loop for each connection
            AC->>GUAC: POST /api/connections<br/>(scicore.guacamole collection)
            GUAC-->>AC: connection created / already exists
        end

        loop for each user
            AC->>GUAC: POST /api/users + grant permissions
            GUAC-->>AC: user created / already exists
        end

        AC->>Op: summary (VMs, users, connections)
    end

    %% ── Stage 4 : Print URLs ─────────────────────────────────────
    rect rgb(240, 230, 255)
        Note over AC,GUAC: Stage 4 — Access URLs [tag: guacamole_url]

        loop for each user
            AC->>GUAC: POST /api/tokens (username + password)
            GUAC-->>AC: authToken
            AC->>Op: http://<bastion_ip>/guacamole/#/?token=<authToken>
        end
    end
```

---

## Step-by-step Explanation

### Stage 0 — Bootstrap

| # | Description |
|---|---|
| 1 | The Lab Admin runs `ansible-playbook site.yml` from their local machine to start the full provisioning. |
| 2 | The Ansible Controller reads `tf_output.json` produced by Terraform to retrieve infrastructure details. |
| 3 | The file returns `bastion_public_ip`, used later to build all Guacamole API URLs. |

### Stage 1 — K8s Cluster

| # | Description |
|---|---|
| 4 | Ansible opens an SSH tunnel through the NAT server using `ProxyCommand` to reach the private K8s network. |
| 5 | The NAT server forwards the SSH connection to the K8s master node. |
| 6 | The NAT server forwards the SSH connection to the K8s worker node. |
| 7 | The `common` role runs on the master — enables and starts the `containerd` container runtime. |
| 8 | The `common` role runs on the worker — same containerd setup. |
| 9 | The `master` role is applied to the master node to initialise the control plane. |
| 10 | `kubeadm init` bootstraps the cluster with pod CIDR `192.168.0.0/16`. |
| 11 | Calico CNI is installed as the cluster network plugin via `kubectl apply`. |
| 12 | The generated `kubeadm join` command is stored as a host fact and shared with the Ansible Controller. |
| 13 | The `worker` role is applied — instructs the worker to join the cluster. |
| 14 | The worker node runs `kubeadm join` using the token provided by the master. |
| 15 | The `clone-repo-guacamole` role runs on the master to deploy the Guacamole application. |
| 16 | The project repository is cloned into `/guacamole/` on the master node. |
| 17 | Guacamole Kubernetes manifests (namespace, postgres, guacd, web, init-job) are applied in the `guacamole` namespace. |
| 18 | Ansible pauses 120 seconds to allow the cluster and Guacamole pods to reach a ready state. |

### Stage 2 — Access Setup

| # | Description |
|---|---|
| 19 | Ansible re-reads `tf_output.json` to get the list of provisioned VM IDs and IPs per connection type. |
| 20 | The file returns VM IDs and IPs for SSH, VNC, and/or Windows VMs depending on what Terraform created. |
| 21 **(ssh)** | For each SSH VM: a NAT PREROUTING iptables rule is added on Proxmox, forwarding `4000+(vmid-400)` → `vm_ip:22`. |
| 22 **(ssh)** | A FORWARD rule is added to allow the forwarded SSH traffic to reach the VM. |
| 21 **(vnc)** | `find_free_vnc.sh` is uploaded to Proxmox — scans ports to find free VNC display slots. |
| 22 **(vnc)** | For each VNC VM: `qm set` applies a `-vnc` argument so the VM exposes a VNC server on a deterministic port. |
| 23 **(vnc)** | An iptables INPUT rule opens the corresponding TCP port (`5915+index`) on Proxmox. |
| 24 **(vnc)** | The VM is restarted (`qm stop && qm start`) to apply the VNC argument change. |
| 21 **(win)** | For each Windows VM: Ansible connects via Evil-WinRM and runs PowerShell to set the network profile to Private and enable the RDP firewall rule. |
| 22 **(win)** | A NAT PREROUTING rule is added forwarding `3310+index` → `vm_ip:3389`. |
| 23 **(win)** | A FORWARD rule is added to allow the RDP traffic through to the VM. |

### Stage 3 — Guacamole Provisioning

| # | Description |
|---|---|
| 30 | Ansible re-reads `tf_output.json` to get VM IDs and the bastion public IP for the Guacamole API base URL. |
| 31 | Returns the full VM ID lists for all connection types plus the bastion IP. |
| 32 | The controller builds the list of Guacamole connections (name, protocol, hostname, port) for each VM. |
| 33 | The controller builds the list of Guacamole users (`<USER_PREFIX>N`) each mapped to their own connection. |
| 34 | For each connection, a `POST /api/connections` call is made to the Guacamole API via the `scicore.guacamole` collection. |
| 35 | Guacamole confirms the connection was created or already exists (idempotent). |
| 36 | For each user, a `POST /api/users` call is made and permissions are granted for their assigned connection(s). |
| 37 | Guacamole confirms the user was created or already exists (idempotent). |
| 38 | Ansible prints a summary: number of VMs, users created vs already existing, connections created vs already existing. |

### Stage 4 — Access URLs

| # | Description |
|---|---|
| 39 | For each provisioned user, a `POST /api/tokens` call authenticates against the Guacamole API with their credentials. |
| 40 | The API returns a short-lived `authToken` for that user's session. |
| 41 | Ansible prints the direct one-click Guacamole URL for the user: `http://<bastion_ip>/guacamole/#/?token=<authToken>`. |

---

## Cleanup Flows

```mermaid
%%{init: {'theme': 'default', 'themeVariables': {'background': '#ffffff', 'mainBkg': '#ffffff', 'textColor': '#000000', 'actorTextColor': '#000000', 'actorBkg': '#f5f5f5', 'actorBorderColor': '#333333', 'signalColor': '#333333', 'signalTextColor': '#000000', 'noteTextColor': '#000000', 'noteBkgColor': '#ffffcc', 'noteBorderColor': '#333333', 'loopTextColor': '#000000', 'activationBorderColor': '#333333', 'activationBkgColor': '#e8e8e8', 'sequenceNumberColor': '#ffffff'}}}%%
sequenceDiagram
    autonumber
    participant Op as Lab Admin<br/>(local machine)
    participant AC as Ansible Controller
    participant TF as tf_output.json
    participant PVE as Proxmox Host

    Op->>AC: ansible-playbook cleanup_ssh.yml<br/>OR cleanup_vnc.yml<br/>OR cleanup_win.yml

    AC->>TF: lookup tf_output.json
    TF-->>AC: vm_ids + vm_ips

    alt cleanup_ssh
        loop for each SSH VM
            AC->>PVE: iptables -D NAT PREROUTING (port 4000+)
            AC->>PVE: iptables -D FORWARD (vm_ip:22)
        end
    else cleanup_vnc
        loop for each VNC VM
            AC->>PVE: qm set vmid --delete args
            AC->>PVE: iptables -D INPUT (port 5915+)
        end
    else cleanup_win
        loop for each Windows VM
            AC->>PVE: iptables -D NAT PREROUTING (port 3310+)
            AC->>PVE: iptables -D FORWARD (vm_ip:3389)
        end
    end

    AC->>Op: done
```

## Cleanup Step-by-step Explanation

| # | Description |
|---|---|
| 1 | The Lab Admin runs one of the three cleanup playbooks — `cleanup_ssh.yml`, `cleanup_vnc.yml`, or `cleanup_win.yml`. |
| 2 | Ansible reads `tf_output.json` to know exactly which VMs were provisioned and their IPs. |
| 3 | Returns the VM IDs and IPs list for the targeted connection type. |
| 4 **(ssh)** | For each SSH VM: the NAT PREROUTING iptables rule (port `4000+`) is removed from Proxmox. |
| 5 **(ssh)** | The FORWARD rule allowing traffic to `vm_ip:22` is also removed. |
| 4 **(vnc)** | For each VNC VM: `qm set vmid --delete args` removes the VNC argument from the VM config. |
| 5 **(vnc)** | The INPUT iptables rule that opened the VNC port (`5915+`) is removed. |
| 4 **(win)** | For each Windows VM: the NAT PREROUTING rule (port `3310+`) is removed from Proxmox. |
| 5 **(win)** | The FORWARD rule allowing traffic to `vm_ip:3389` is removed. |
| 6 | Ansible confirms all rules have been removed and the cleanup is complete. |
