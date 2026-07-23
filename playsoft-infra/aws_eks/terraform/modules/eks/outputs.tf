output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  value     = aws_eks_cluster.this.certificate_authority[0].data
  sensitive = true
}

output "cluster_oidc_issuer_url" {
  description = "Hand this to Abdallah to set up the OIDC provider + IRSA roles"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}
