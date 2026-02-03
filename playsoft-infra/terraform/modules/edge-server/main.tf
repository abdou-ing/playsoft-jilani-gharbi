terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.59.0"
    }
  }
}

resource "hcloud_server" "edge" {
  name        = "hzn-bastion-jilani"
  image       = data.hcloud_image.bastion_snapshot.id
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [var.ssh_key_name]
 

  user_data = file("${path.module}/../../cloud-init/edge.yaml")

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = var.network_id
    ip         = var.edge_private_ip
  }
}

data "hcloud_image" "bastion_snapshot" {
  with_selector = "created_by=jilani,role=bastion"
  most_recent   = true
}

# Firewall
resource "hcloud_firewall" "edge_fw" {
  name = "fw-bastion-jilani"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"] # ← Consider restricting!
  }
}

resource "hcloud_firewall_attachment" "edge_attach" {
  firewall_id = hcloud_firewall.edge_fw.id
  server_ids  = [hcloud_server.edge.id]
}

