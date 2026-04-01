output "k8s_master_private_ip" {
  value = module.k8s_cluster.master_private_ip
}

output "k8s_worker_private_ips" {
  value = module.k8s_cluster.worker_private_ips
}

output "bastion_public_ip" {
  value = module.edge.public_ip
}
