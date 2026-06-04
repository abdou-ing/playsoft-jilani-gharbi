output "master_private_ip" {
  value = var.master_private_ip
}

output "worker_private_ips" {
  value = [for i, w in hcloud_server.worker : cidrhost(var.network_cidr, 11 + i)]
}
