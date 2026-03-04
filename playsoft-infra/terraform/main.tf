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
  my_ip           = var.my_ip
}

module "guacamole" {
  source = "./modules/guacamole-server"

  location             = var.location
  server_type          = var.server_type
  ssh_key_name         = var.ssh_key_name
  guacamole_private_ip = var.guacamole_private_ip
  network_id           = data.hcloud_network.main.id
}

resource "local_file" "ssh_config" {
  content  = <<-EOT
    Host bastion
      HostName ${module.edge.public_ip}
      User root
      IdentityFile ~/.ssh/jilani

    Host guacamole
      HostName 10.20.0.3
      User root
      IdentityFile ~/.ssh/jilani
      ProxyJump bastion
  EOT
  filename = pathexpand("~/.ssh/config")
}
    # module "centos" {
    #   source = "./modules/centos-server"

    #   location          = var.location
    #   server_type       = var.server_type
    #   ssh_key_name      = var.ssh_key_name
    #   centos_private_ip = var.centos_private_ip
    #   edge_private_ip   = var.edge_private_ip
    #   my_ip             = var.my_ip
    #   network_id        = data.hcloud_network.main.id
    #   server_count      = var.server_count
    # }

