# Edge server (Bastion + NAT)
resource "hcloud_server" "edge" {
  name        = "hzn-bastion-jilani"
  image       = "ubuntu-22.04"
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [var.ssh_key_name]

  user_data = file("${path.module}/cloud-init/edge.yaml")

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = data.hcloud_network.main.id
    ip         = var.edge_private_ip
  }
}

# Guacamole server (private only)
resource "hcloud_server" "guacamole" {
  name        = "hzn-guacamole-jilani"
  image       = "ubuntu-22.04"
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [var.ssh_key_name]

  user_data = file("${path.module}/cloud-init/guacamole.yaml")

  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }

  network {
    network_id = data.hcloud_network.main.id
    ip         = var.guacamole_private_ip
  }
}
