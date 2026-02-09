source "proxmox-clone" "kali" {
  proxmox_url = var.proxmox_api_url
  username    = var.proxmox_api_token_id
  token       = var.proxmox_api_token_secret

  node = var.proxmox_node

  clone_vm_id = var.source_template_id

  vm_id   = var.new_template_id
  vm_name = var.new_template_name

  ssh_username = var.ssh_user
  ssh_password = var.ssh_password

  insecure_skip_tls_verify = true
  ssh_timeout  = "10m"
}

build {
  name    = "kali-vnc-template"
  sources = ["source.proxmox-clone.kali"]

  provisioner "shell" {
    script = "provision/configure_vnc.sh"
  }
}
