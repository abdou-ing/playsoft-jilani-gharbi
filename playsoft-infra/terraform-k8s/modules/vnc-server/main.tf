resource "proxmox_virtual_environment_vm" "vm" {
  node_name = var.node_name
  name      = "redhat-exam-vnc-${var.vm_id}"
  vm_id     = var.vm_id

  agent {
    enabled = false
  }

  clone {
    vm_id        = var.template_id
    full         = true
    datastore_id = "local"
  }
}