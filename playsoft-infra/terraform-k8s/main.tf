module "k8s_master" {
  source = "./modules/k8s-master"

  location                  = var.master_location
  server_type               = var.server_type
  ssh_keys                  = [var.ssh_key_name]
  network_id                = data.hcloud_network.main.id
  master_count              = var.master_count
  master_base_offset        = var.master_base_offset
  network_cidr              = var.private_network_cidr
  gateway_ip                = var.gateway_ip
  environment               = var.environment
  delete_rebuild_protection = var.delete_rebuild_protection
}

module "k8s_worker" {
  source = "./modules/k8s-worker"

  location           = var.worker_location
  server_type        = var.server_type
  ssh_keys           = [var.ssh_key_name]
  network_id         = data.hcloud_network.main.id
  worker_count       = var.worker_count
  worker_base_offset = var.worker_base_offset
  network_cidr       = var.private_network_cidr
  gateway_ip         = var.gateway_ip
  environment        = var.environment
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
  lb_ip                = module.k8s_lb.load_balancer_private_ip
}

module "monitoring" {
  source = "./modules/monitoring-server"

  location               = var.monitoring_location
  server_type            = var.monitoring_server_type
  ssh_key_name           = var.ssh_key_name
  network_id             = data.hcloud_network.main.id
  monitoring_private_ip  = var.monitoring_private_ip
  my_ip                  = var.my_ip
}

module "k8s_lb" {
  source = "./modules/load-balancer"

  lb_name                   = "lb-k8s-${var.environment}"
  location                  = var.location
  network_id                = data.hcloud_network.main.id
  # NOTE: matches the live target selector on lb-k8s-dev (verified via
  # `hcloud load-balancer describe lb-k8s-dev`) -- it was changed out-of-band
  # to target masters, not workers, and this code previously still said
  # "role=k8s-worker,env=${var.environment}". Left as-is would have reverted
  # the live LB to the wrong target set (and dropped the 6443 service below)
  # on the next apply. See modules/k8s-master's `role=k8s-master` label.
  server_labels             = "role=k8s-master"
  environment               = var.environment
  delete_rebuild_protection = var.delete_rebuild_protection

  #depends_on = [module.k8s_master, module.k8s_worker]
}


module "vnc_server" {
  count  = var.vnc_server_count
  source = "./modules/vnc-server"
  vm_id  = 801 + count.index

  node_name   = var.node_name
  template_id = var.template_id
}

module "ssh_server" {
  count  = var.ssh_server_count
  source = "./modules/ssh-server"
  vm_id  = 910 + count.index

  node_name   = var.node_name
  template_id = var.template_id
}

# module "windows_vm" {
#   source = "./modules/windows-vm"

#   node_name    = var.node_name
#   template_id  = var.windows_template_id
#   server_count = var.windows_server_count
#   vm_id        = 401
# }

