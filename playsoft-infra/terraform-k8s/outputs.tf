output "k8s_master_private_ips" {
  value = module.k8s_master.master_private_ips
}

output "k8s_worker_private_ips" {
  value = module.k8s_worker.worker_private_ips
}

output "bastion_public_ip" {
  value = module.edge.public_ip
}

output "load_balancer_public_ip" {
  value       = module.k8s_lb.load_balancer_ipv4
  description = "Public IP of the Kubernetes load balancer"
}

# output "vnc_vm_ids" {
#   value = module.vnc_server[*].vm_ids
# }

# output "vnc_vm_ips" {
#   value = [for server in module.vnc_server : server.primary_ipv4_address]
# }

# output "windows_vm_ids" {
#   value = module.windows_vm.vm_ids
# }

# output "windows_vm_ips" {
#   value = module.windows_vm.primary_ipv4_addresses
# }










