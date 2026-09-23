output "region" {
  value = var.region
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "update_kubeconfig_command" {
  description = "Run this to point kubectl at the new cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "lb_controller_role_arn" {
  description = "Pass-through of var.lb_controller_role_arn, for deploy.sh"
  value       = var.lb_controller_role_arn
}

output "bastion_public_ip" {
  description = "SSH here first, then hop to a node's private IP"
  value       = module.eks.bastion_public_ip
}

# ── Candidate target VMs on Proxmox (consumed by ansible/aws-eks/) ───────
# Same output names/shapes as terraform/hetzner's outputs.tf so the
# ansible/aws-eks roles (guacamole_connection, guacamole_url, ssh_setup,
# vnc_setup) work unchanged when pointed at this project's tf_output.json
# instead of terraform/hetzner's.
output "ssh_vm_ids" {
  value = module.ssh_server[*].vm_ids
}
#
output "ssh_vm_ips" {
  value = [for server in module.ssh_server : server.primary_ipv4_address]
}
#
output "vnc_vm_ids" {
  value = module.vnc_server[*].vm_ids
}
#
output "vnc_vm_ips" {
  value = [for server in module.vnc_server : server.primary_ipv4_address]
}
