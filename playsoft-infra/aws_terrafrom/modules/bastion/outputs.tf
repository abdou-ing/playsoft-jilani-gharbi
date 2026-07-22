output "security_group_id" {
  value = aws_security_group.bastion.id
}

output "public_ip" {
  description = "SSH here"
  value       = aws_eip.bastion.public_ip
}

output "private_ip" {
  description = "Bastion's address inside the VPC"
  value       = aws_instance.bastion.private_ip
}
