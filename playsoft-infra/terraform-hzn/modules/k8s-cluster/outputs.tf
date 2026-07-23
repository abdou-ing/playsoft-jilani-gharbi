output "master_private_ip" {
  value = var.master_private_ip
}

output "worker_private_ips" {
  value = [for index, worker in hcloud_server.worker : cidrhost(var.network_cidr, var.worker_base_offset + index)]
}
