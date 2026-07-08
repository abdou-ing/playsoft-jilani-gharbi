output "public_ip" {
  value = hcloud_server.monitoring.ipv4_address
}

output "private_ip" {
  value = var.monitoring_private_ip
}
