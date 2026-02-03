# main.tf

data "hcloud_network" "main" {
  name = "nw-jilani" 
}

module "edge" {
  source = "./modules/edge-server"

  location        = var.location
  server_type     = var.server_type
  ssh_key_name    = var.ssh_key_name
  edge_private_ip = var.edge_private_ip
  network_id      = data.hcloud_network.main.id
}

module "guacamole" {
  source = "./modules/guacamole-server"

  location             = var.location
  server_type          = var.server_type
  ssh_key_name         = var.ssh_key_name
  guacamole_private_ip = var.guacamole_private_ip
  network_id           = data.hcloud_network.main.id
}