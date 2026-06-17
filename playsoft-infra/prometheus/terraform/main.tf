data "hcloud_network" "main" {
  name = "nw-jilani"
}

module "k8s_cluster" {
  source = "./modules/k8s-worker"

  location    = var.location
  server_type = var.server_type
  ssh_keys    = var.ssh_keys
  network_id  = data.hcloud_network.main.id
  workers     = var.workers
  gateway_ip  = var.gateway_ip
  environment = var.environment
  server_name = var.server_name
}
