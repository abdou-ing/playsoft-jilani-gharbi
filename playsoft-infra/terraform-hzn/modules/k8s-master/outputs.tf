output "master_private_ips" {
  value = [for index, master in hcloud_server.master : cidrhost(var.network_cidr, var.master_base_offset + index)]
}

output "server_ids" {
  value = hcloud_server.master[*].id
}
