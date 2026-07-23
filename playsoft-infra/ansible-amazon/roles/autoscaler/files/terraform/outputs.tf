output "worker_map" {
  description = "{name: private_ip} of every autoscaler-managed worker this state currently owns -- webhook.py's get_managed_workers() reads this."
  value       = { for name, inst in aws_instance.worker : name => inst.private_ip }
}
