resource "proxmox_virtual_environment_vm" "vm" {
  node_name = var.node_name
  name      = var.vm_name

  agent {
    enabled = false
  }

  clone {
    vm_id        = var.template_id
    full         = true
    datastore_id = "local"
  }
}

