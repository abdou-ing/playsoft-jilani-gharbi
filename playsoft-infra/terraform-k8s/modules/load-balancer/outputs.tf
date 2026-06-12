output "load_balancer_id" {
  value = module.hetzner_lb.load_balancer_id
}

output "load_balancer_ipv4" {
  value = module.hetzner_lb.load_balancer_ipv4
}

output "load_balancer_private_ip" {
  value = module.hetzner_lb.load_balancer_private_ip
}
