module "k8s_cluster" {
  source = "./modules/k8s-cluster"

  location          = var.location
  server_type       = var.server_type
  ssh_key_name      = var.ssh_key_name
  network_id        = data.hcloud_network.main.id
  worker_count      = var.worker_count
  master_private_ip = var.k8s_master_private_ip
}

module "edge" {
  source = "./modules/edge-server"

  location = var.location
  server_type = var.server_type
  ssh_key_name = var.ssh_key_name
  network_id = data.hcloud_network.main.id
  edge_private_ip = var.edge_private_ip
  my_ip = var.my_ip
}

