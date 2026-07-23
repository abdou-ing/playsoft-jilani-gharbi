output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "control_plane_endpoint" {
  description = "Use as --control-plane-endpoint (host:6443)"
  value       = "${module.k8s_master.private_ip}:6443"
}

output "alb_dns_name" {
  description = "Public DNS for the app"
  value       = module.load_balancer.alb_dns_name
}

output "master_instance_id" {
  value = module.k8s_master.instance_id
}

output "worker_instance_id" {
  value = module.k8s_worker.instance_id
}

output "master_private_ip" {
  description = "Fixed private IP of the master EC2 instance"
  value       = module.k8s_master.private_ip
}

output "worker_private_ip" {
  description = "Fixed private IP of the floor worker EC2 instance"
  value       = module.k8s_worker.private_ip
}

output "monitoring_public_ip" {
  description = "Grafana (:3000) / Prometheus (:9090) / SSH here, restricted to admin_cidr"
  value       = module.monitoring.public_ip
}

output "monitoring_private_ip" {
  value = module.monitoring.private_ip
}

output "bastion_public_ip" {
  description = "SSH here"
  value       = module.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Bastion's address inside the VPC"
  value       = module.bastion.private_ip
}
