module "k8s_cluster" {
  source = "./modules/k8s-cluster"

  location          = var.location
  server_type       = var.server_type
  ssh_key_name      = var.ssh_key_name
  network_id        = data.hcloud_network.main.id
  worker_count      = var.worker_count
  master_private_ip = var.k8s_master_private_ip
  gateway_ip        = var.gateway_ip
  network_cidr      = var.private_network_cidr
}

module "edge" {
  source = "./modules/edge-server"

  location        = var.location
  server_type     = var.server_type
  ssh_key_name    = var.ssh_key_name
  network_id      = data.hcloud_network.main.id
  edge_private_ip      = var.edge_private_ip
  my_ip                = var.my_ip
  private_network_cidr = var.private_network_cidr
}

module "vnc_server" {
  count  = var.vnc_server_count
  source = "./modules/vnc-server"
  vm_id  = var.vnc_base_vm_id + count.index

  node_name   = var.node_name
  template_id = var.template_id
}

module "windows_server" {
  count  = var.windows_server_count
  source = "./modules/vnc-server"
  vm_id  = var.windows_base_vm_id + count.index

  node_name   = var.node_name
  template_id = var.windows_template_id
}


