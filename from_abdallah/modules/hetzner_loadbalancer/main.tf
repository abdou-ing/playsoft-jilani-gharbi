terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud" # Uncomment and fix this line
      # Don't specify version in modules - let root config handle it
    }
  }
}


#resource "hcloud_managed_certificate" "managed_cert" {
#  name         = var.cert_name
#  domain_names = var.cert_domain_names
#}

resource "hcloud_load_balancer" "load_balancer" {
  name               = var.lb_name
  load_balancer_type = var.lb_server_type
  location           = var.lb_location
  delete_protection  = var.delete_rebuild_protection
  algorithm {
    type = var.lb_type
  }
  labels = {
    name = var.lb_name
    env  = var.environment
  }
}

resource "hcloud_load_balancer_network" "private_network" {
  load_balancer_id        = hcloud_load_balancer.load_balancer.id
  network_id              = var.network_id != null ? var.network_id : data.hcloud_networks.private_networks[0].networks[0].id
  enable_public_interface = true
}

resource "hcloud_load_balancer_service" "load_balancer_service" {
  load_balancer_id = hcloud_load_balancer.load_balancer.id
  protocol         = "tcp"
  listen_port      = var.listen_port
  destination_port = var.destination_port
}

resource "hcloud_load_balancer_target" "load_balancer_target" {
  type             = "label_selector"
  load_balancer_id = hcloud_load_balancer.load_balancer.id
  label_selector   = var.server_labels
  use_private_ip   = true

  depends_on = [hcloud_load_balancer_network.private_network]
}