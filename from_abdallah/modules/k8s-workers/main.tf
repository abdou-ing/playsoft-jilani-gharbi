terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud" # Uncomment and fix this line
      # Don't specify version in modules - let root config handle it
    }
  }
}


# Worker Servers
resource "hcloud_server" "worker" {
  name        = "${var.server_name}-${var.environment}"
  image       = data.hcloud_image.k8s_snapshot.id
  server_type = var.server_type
  location    = var.server_location
  ssh_keys    = var.ssh_keys

  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }

  network {
    network_id = data.hcloud_networks.private_networks.networks[0].id
    #ip         = cidrhost(var.network_cidr, var.worker_base_offset + count.index)
    alias_ips  = []
  }

  user_data = templatefile("${path.module}/cloud-init.yml", {
    gateway_ip = var.gateway_ip  # Pass the gateway ip variable
  })

  labels = {
    role : "k8s-worker"
    name : var.server_name
    env : var.environment
    location : var.server_location
  }
}
