output "security_group_id" {
  value = aws_security_group.worker.id
}

output "asg_name" {
  value = aws_autoscaling_group.worker.name
}

output "private_ips" {
  description = "Private IPs of the current worker ASG instances"
  value       = data.aws_instances.worker.private_ips
}
