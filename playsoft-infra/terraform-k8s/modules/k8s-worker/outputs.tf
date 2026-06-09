output "worker_private_ips" {
  value = [for index, worker in hcloud_server.worker : cidrhost(var.network_cidr, var.worker_base_offset + index)]
}

output "server_ids" {
  value = hcloud_server.worker[*].id
}
