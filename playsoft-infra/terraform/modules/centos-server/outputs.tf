output "server_id" {
  value = hcloud_server.centos.id
}

output "server_ip" {
  value = hcloud_server.centos.network[*].ip
}
