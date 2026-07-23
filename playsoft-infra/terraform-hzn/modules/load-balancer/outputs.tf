output "load_balancer_id" {
  value = hcloud_load_balancer.this.id
}

output "load_balancer_ipv4" {
  value = hcloud_load_balancer.this.ipv4
}

output "load_balancer_private_ip" {
  value = hcloud_load_balancer_network.this.ip
}
