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
    alias_ips = []
  }
}

# Firewall
resource "hcloud_firewall" "edge_fw" {
  name = "fw-bastion-jilani"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = [var.my_ip]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = [var.my_ip]
  }
    rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "8080"
    source_ips = [var.my_ip]
  }
 rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
    source_ips = [var.my_ip]
  }

  # Kubelet
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "10250"
    source_ips = [var.my_ip]
  }

  # NodePort services
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "30000-32767"
    source_ips = [var.my_ip]
  }
}

resource "hcloud_firewall_attachment" "edge_attach" {
  firewall_id = hcloud_firewall.edge_fw.id
  server_ids  = [hcloud_server.edge.id]
}

