module "hetzner_lb" {
  source = "../../../../from_abdallah/modules/hetzner_loadbalancer"

  hcloud_token              = ""
  lb_name                   = var.lb_name
  lb_location               = var.location
  lb_server_type            = var.lb_server_type
  lb_type                   = var.lb_algorithm
  network_id                = var.network_id
  server_labels             = var.server_labels
  environment               = var.environment
  delete_rebuild_protection = var.delete_rebuild_protection
  listen_port               = 80
  destination_port          = 30880
}

resource "hcloud_load_balancer_service" "https" {
  load_balancer_id = module.hetzner_lb.load_balancer_id
  protocol         = "tcp"
  listen_port      = 443
  destination_port = 30443

  health_check {
    protocol = "tcp"
    port     = 30443
    interval = 15
    timeout  = 10
    retries  = 3
  }
}
