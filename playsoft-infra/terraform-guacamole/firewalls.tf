# Firewall for edge server
resource "hcloud_firewall" "edge_fw" {
  name = "fw-bastion-jilani"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

# Attach firewall to edge
resource "hcloud_firewall_attachment" "edge_attach" {
  firewall_id = hcloud_firewall.edge_fw.id
  server_ids  = [hcloud_server.edge.id]
}