module "vm1" {
  source = "./modules/vm"
  count  = var.server_count

  node_name   = "playsoft-proxmox"
  vm_name     = "redhat-exam-vnc-${count.index + 1}"
  template_id = 116

  cpu       = 2
  memory    = 2048
  disk_size = 20

  storage = "local"       
  bridge  = "vmbr0"
  vm_id   = var.vm_id + count.index

  ssh_public_key = "~/.ssh/jlani.pub"
}