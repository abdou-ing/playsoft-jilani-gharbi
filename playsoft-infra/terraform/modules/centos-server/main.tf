terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.59.0"
    }
  }
}

resource "hcloud_server" "centos" {
  name        = "hzn-centos-jilani"
  image       = "centos-stream-10"
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [var.ssh_key_name]
  
  

  #user_data = file("${path.module}/../../cloud-init/centos.yaml")

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = var.network_id
    ip         = var.centos_private_ip
  }
}
