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

output "worker_asg_name" {
  value = module.k8s_worker.asg_name
}

output "master_private_ip" {
  description = "Fixed private IP of the master EC2 instance"
  value       = module.k8s_master.private_ip
}

output "worker_private_ips" {
  description = "Private IPs of the current worker EC2 instances"
  value       = module.k8s_worker.private_ips
}

output "bastion_public_ip" {
  description = "SSH here"
  value       = module.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Bastion's address inside the VPC"
  value       = module.bastion.private_ip
}
