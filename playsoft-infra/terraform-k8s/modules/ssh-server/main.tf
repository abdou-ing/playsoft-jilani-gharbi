resource "proxmox_virtual_environment_file" "cloud_init_user_data" {
  node_name    = var.node_name
  datastore_id = var.cloud_init_datastore_id
  content_type = "snippets"
  overwrite    = true

  source_raw {
    data      = var.cloud_init_snippet
    file_name = "ssh-server-${var.vm_id}-user-data.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  node_name = var.node_name
  name      = "redhat-exam-ssh-${var.vm_id}"
  vm_id     = var.vm_id

  agent {
    enabled = true
  }

  clone {
    vm_id        = var.template_id
    full         = true
    datastore_id = "local"
  }

  lifecycle {
    ignore_changes = [clone]
  }

  initialization {
    datastore_id      = var.cloud_init_datastore_id
    user_data_file_id = proxmox_virtual_environment_file.cloud_init_user_data.id
  }
}
