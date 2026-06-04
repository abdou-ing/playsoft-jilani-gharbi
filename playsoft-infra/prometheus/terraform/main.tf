data "hcloud_network" "main" {
  name = "nw-jilani"
}

module "k8s_cluster" {
  source = "./modules/k8s-worker"

  location          = var.location
  server_type       = var.server_type
  ssh_key_name      = var.ssh_key_name
  network_id        = data.hcloud_network.main.id
  worker_count      = var.worker_count
  master_private_ip = var.k8s_master_private_ip
  gateway_ip        = var.gateway_ip
  network_cidr      = var.private_network_cidr
}
