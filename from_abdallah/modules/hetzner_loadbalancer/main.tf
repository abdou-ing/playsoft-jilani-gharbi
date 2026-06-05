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
  name               = "instalab-load-balancer"
  load_balancer_type = var.lb_server_type
  location           = var.lb_location
  delete_protection  = var.delete_rebuild_protection
  algorithm {
    type = var.lb_type
  }
  labels = {
    name : "lb-instalab"
    env : var.environment
  }

}

resource "hcloud_load_balancer_network" "private_network" {
  load_balancer_id = hcloud_load_balancer.load_balancer.id
  network_id       = data.hcloud_networks.private_networks.networks[0].id
  #ip               = var.loadbalancer_private_ip
  enable_public_interface = false


  # **Note**: the depends_on is important when directly attaching the
  # server to a network. Otherwise Terraform will attempt to create
  # server and sub-network in parallel. This may result in the server
  # creation failing randomly.
  #depends_on = [
  #  hcloud_network_subnet.foonet
  #]
}

resource "hcloud_load_balancer_service" "load_balancer_service" {
  load_balancer_id = hcloud_load_balancer.load_balancer.id

  # Change #1: The `protocol` value switched from "http" to "https"
  protocol = "tcp"
  listen_port = 80
  destination_port = 30080

  # Change #2: Added a new `http` block.
  #http {
  #  redirect_http = true
  #  certificates  = [hcloud_managed_certificate.managed_cert.id]
  #  #certificates  = [data.hcloud_certificate.totolabbyfr.id]
  #  sticky_sessions = true
  #  cookie_name     = "INSTALAB_STICKY"
  #}

  #health_check {
  #  protocol = "http"
  #  port     = 80
  #  interval = 10
  #  timeout  = 5
  #  retries  = 5
#
  #  http {
  #    path         = "/"
  #    status_codes = ["2??", "3??"]
  #  }
  #}
}

resource "hcloud_load_balancer_target" "load_balancer_target" {
  type             = "label_selector"
  load_balancer_id = hcloud_load_balancer.load_balancer.id
  label_selector   = var.server_labels
  use_private_ip = true
}