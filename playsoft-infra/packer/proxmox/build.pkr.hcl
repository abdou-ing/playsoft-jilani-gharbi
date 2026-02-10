source "proxmox-clone" "kali" {
  proxmox_url = var.proxmox_api_url
  username    = var.proxmox_username
  token       = var.proxmox_token

  ssh_username = var.ssh_username
  ssh_password = var.ssh_password


  node                     = var.proxmox_node
  clone_vm_id              = var.source_vm_id
  vm_id                    = var.new_vm_id
  template_name            = var.template_name
  full_clone               = true
  insecure_skip_tls_verify = true

  cores  = var.cpu_cores
  memory = var.memory
}
