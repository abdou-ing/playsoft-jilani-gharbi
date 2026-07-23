resource "hcloud_server" "monitoring" {
  name        = "hzn-monitoring-jilani"
  image       = data.hcloud_image.bastion_snapshot.id
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [var.ssh_key_name]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = var.network_id
    ip         = var.monitoring_private_ip
    alias_ips  = []
  }

  labels = {
    role       = "monitoring"
    created_by = "jilani"
  }
}

# Grafana (3000) and Prometheus (9090) are admin surfaces, not public services --
# restricted to my_ip same as the other admin ports on the bastion's firewall.
resource "hcloud_firewall" "monitoring_fw" {
  name = "fw-monitoring-jilani"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = [var.my_ip]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "3000"
    source_ips = [var.my_ip]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "9090"
    source_ips = [var.my_ip]
  }
}

resource "hcloud_firewall_attachment" "monitoring_attach" {
  firewall_id = hcloud_firewall.monitoring_fw.id
  server_ids  = [hcloud_server.monitoring.id]
}
