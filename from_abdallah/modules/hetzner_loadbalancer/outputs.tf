output "load_balancer_id" {
  value = hcloud_load_balancer.load_balancer.id
}

output "load_balancer_ipv4" {
  value = hcloud_load_balancer.load_balancer.ipv4
}

output "load_balancer_private_ip" {
  value = hcloud_load_balancer_network.private_network.ip
}
