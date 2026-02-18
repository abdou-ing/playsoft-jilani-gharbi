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

  ssh_public_key = "pub key path"
}

module "vm2" {
  source = "./modules/vm"

  node_name   = "playsoft-proxmox"
  vm_name     = "almaLinux-vnc"
  template_id = 113

  cpu       = 2
  memory    = 2048
  disk_size = 20

  storage = "local"       
  bridge  = "vmbr0"

  ssh_public_key = "pub key path"
}