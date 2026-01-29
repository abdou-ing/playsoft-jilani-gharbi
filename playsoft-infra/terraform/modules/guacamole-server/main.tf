terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.59.0"
    }
  }
}

data "hcloud_network" "main" {
  name = "nw-jilani"  
}

resource "hcloud_server" "guacamole" {
  name        = "hzn-guacamole-jilani"
  image       = data.hcloud_image.guacamole_snapshot.id
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [var.ssh_key_name]


  user_data = file("${path.module}/../../cloud-init/guacamole.yaml")

  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }

  network {
    network_id = var.network_id
    ip         = var.guacamole_private_ip
  }
}

data "hcloud_image" "guacamole_snapshot" {
  with_selector = "created_by=jilani,role=guacamole"
  most_recent   = true
}