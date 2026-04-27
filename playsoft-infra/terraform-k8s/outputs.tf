output "k8s_master_private_ip" {
  value = module.k8s_cluster.master_private_ip
}

output "k8s_worker_private_ips" {
  value = module.k8s_cluster.worker_private_ips
}

output "bastion_public_ip" {
  value = module.edge.public_ip
}

output "vnc_vm_ids" {
  value = module.vnc_server[*].vm_ids
}

output "windows_vm_ids" {
  value = module.windows_server[*].vm_ids
}

output "vm_ips" {
  value = concat(
    [for module in module.vnc_server : module.primary_ipv4_address],
    [for module in module.windows_server : module.primary_ipv4_address]
  )
}










