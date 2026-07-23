output "security_group_id" {
  value = aws_security_group.monitoring.id
}

output "public_ip" {
  description = "Grafana/Prometheus/SSH here (restricted to admin_cidr)"
  value       = aws_eip.monitoring.public_ip
}

output "private_ip" {
  description = "Monitoring host's address inside the VPC (node_exporter scrape path to master/worker)"
  value       = aws_instance.monitoring.private_ip
}
