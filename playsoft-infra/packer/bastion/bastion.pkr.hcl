packer {
  required_plugins {
    hcloud = {
      source  = "github.com/hashicorp/hcloud"
      version = ">= 1.4.0"
    }
  }
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}

source "hcloud" "bastion" {
  token        = var.hcloud_token
  image        = "ubuntu-24.04"
  server_type  = "cx23"
  location     = "hel1"
  ssh_username = "root"
  snapshot_name = "hzn-bastion-jilani-snap"
  snapshot_labels = {
    created_by = "jilani" 
    role       = "bastion"
  }
}

build {
  name    = "bastion-image"
  sources = ["source.hcloud.bastion"]

  provisioner "shell" {
    script = "provision.sh"
  }
}
