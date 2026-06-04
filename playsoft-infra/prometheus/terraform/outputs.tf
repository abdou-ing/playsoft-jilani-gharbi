output "master_private_ip" {
  value = module.k8s_cluster.master_private_ip
}

output "worker_private_ips" {
  value = module.k8s_cluster.worker_private_ips
}
