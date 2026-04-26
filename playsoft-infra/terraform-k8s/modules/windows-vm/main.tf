resource "proxmox_virtual_environment_vm" "windows_vm" {
  count     = var.server_count
  node_name = var.node_name
  name      = "windows-server-${var.vm_id + count.index}"
  vm_id     = var.vm_id + count.index
  machine   = "q35"
  bios      = "ovmf"

  agent {
    enabled = true
    timeout = "2m"
  }

  clone {
    vm_id        = var.template_id
    full         = true
    datastore_id = "local"
  }

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 4096
  }

  operating_system {
    type = "win11"
  }

  efi_disk {
    datastore_id = "local"
    type         = "4m"
  }

  tpm_state {
    datastore_id = "local"
    version      = "v2.0"
  }
}
