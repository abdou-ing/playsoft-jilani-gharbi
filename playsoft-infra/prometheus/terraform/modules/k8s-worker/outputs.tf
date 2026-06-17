output "worker_map" {
  value = { for name, s in hcloud_server.worker : name => var.workers[name] }
}

output "server_ids" {
  value = { for name, s in hcloud_server.worker : name => s.id }
}
