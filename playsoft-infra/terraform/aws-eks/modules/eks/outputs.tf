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

output "bastion_public_ip" {
  description = "SSH here first, then hop to a node's private IP (empty if ssh_key_name is unset)"
  value       = try(aws_instance.bastion[0].public_ip, "")
}

