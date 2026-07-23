output "security_group_id" {
  value = aws_security_group.worker.id
}

output "instance_id" {
  value = aws_instance.worker.id
}

output "private_ip" {
  description = "Fixed private IP of the floor worker"
  value       = aws_instance.worker.private_ip
}
