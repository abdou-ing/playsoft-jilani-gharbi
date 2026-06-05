terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud" # Uncomment and fix this line
      # Don't specify version in modules - let root config handle it
    }
  }
}


# Master Server
resource "hcloud_server" "master" {
  name        = "${var.server_name}-${var.environment}"
  image       = data.hcloud_image.k8s_snapshot.id
  server_type = var.server_type
  location    = var.server_location
  delete_protection  = var.delete_rebuild_protection
  rebuild_protection = var.delete_rebuild_protection
  ssh_keys    = var.ssh_keys

  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }

  network {
    network_id = data.hcloud_networks.private_networks.networks[0].id
    #ip         = var.master_private_ip
    alias_ips  = []

  }

  user_data = templatefile("${path.module}/cloud-init.yml", {
    gateway_ip = var.gateway_ip
  })

  labels = {
    role : "k8s-master"
    name : var.server_name
    env : var.environment
    location : var.server_location
  }
}
