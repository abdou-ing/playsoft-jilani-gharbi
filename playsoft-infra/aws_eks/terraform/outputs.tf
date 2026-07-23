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

output "cluster_oidc_issuer_url" {
  description = "Hand this to Abdallah once the first apply is done -- he needs it to create the OIDC provider + the ebs-csi/lb-controller IRSA roles"
  value       = module.eks.cluster_oidc_issuer_url
}

output "lb_controller_role_arn" {
  description = "Pass-through of var.lb_controller_role_arn, for deploy.sh"
  value       = var.lb_controller_role_arn
}
