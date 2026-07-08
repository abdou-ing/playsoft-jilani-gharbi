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
}

resource "hcloud_load_balancer_service" "https" {
  load_balancer_id = module.hetzner_lb.load_balancer_id
  protocol         = "tcp"
  listen_port      = 480
  destination_port = 30080

  health_check {
    protocol = "tcp"
    port     = 30080
    interval = 15
    timeout  = 10
    retries  = 3
  }
}

# Apiserver passthrough -- exists live on lb-k8s-dev (verified via `hcloud
# load-balancer describe lb-k8s-dev`) but was missing from this module. It's
# what lets Vault (external) reach the cluster's apiserver through the LB for
# Kubernetes-auth TokenReview calls (see ansible/roles/k8s-vault/VAULT_INTEGRATION.md).
# Without this block, applying this module would have deleted the live service.
resource "hcloud_load_balancer_service" "apiserver" {
  load_balancer_id = module.hetzner_lb.load_balancer_id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443

  health_check {
    protocol = "tcp"
    port     = 6443
    interval = 15
    timeout  = 10
    retries  = 3
  }

#   resource "hcloud_load_balancer_service" "apiserver" {
#   load_balancer_id = module.hetzner_lb.load_balancer_id
#   protocol         = "tcp"
#   listen_port      = 80
#   destination_port = 6443

#   health_check {
#     protocol = "tcp"
#     port     = 6443
#     interval = 15
#     timeout  = 10
#     retries  = 3
#   }
  
# }
}
