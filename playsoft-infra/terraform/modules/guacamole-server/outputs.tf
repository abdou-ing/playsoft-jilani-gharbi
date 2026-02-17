# Output: private IP
output "private_ip" {
  value = one(hcloud_server.guacamole.network).ip
}