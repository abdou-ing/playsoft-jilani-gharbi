source "proxmox-clone" "kali" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_username
  token                    = var.proxmox_token

  node                     = var.proxmox_node
  clone_vm_id              = var.source_vm_id
  vm_id                    = var.new_vm_id
  template_name            = var.template_name
  full_clone               = true
  insecure_skip_tls_verify = true

  cores  = var.cpu_cores
  memory = var.memory

  # Private VM
  ssh_host               = "10.0.x.x"
  ssh_username           = "bob"
  ssh_private_key_file   = "path of private key to inject into the VM"

  # Bastion (Proxmox public IP)
  ssh_bastion_host             = "123.45.x.x"
  ssh_bastion_username         = var.ssh_username
  ssh_bastion_private_key_file = "path of private key to access Proxmox"
}
