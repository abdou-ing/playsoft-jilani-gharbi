module "vm1" {
  source = "./modules/vm"

  node_name   = "playsoft-proxmox"
  vm_name     = "terraform-vnc"
  template_id = 200

  cpu       = 2
  memory    = 2048
  disk_size = 20

  storage = "local"       
  bridge  = "vmbr0"
  vm_id   = var.vm_id

  ssh_public_key = "~/.ssh/jlani.pub"
}