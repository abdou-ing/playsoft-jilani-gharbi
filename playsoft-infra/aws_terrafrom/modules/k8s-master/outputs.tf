output "security_group_id" {
  value = aws_security_group.master.id
}

output "instance_id" {
  value = aws_instance.master.id
}

output "private_ip" {
  description = "Fixed private IP of the master -- use as the kubeadm join / --control-plane-endpoint target"
  value       = aws_instance.master.private_ip
}
