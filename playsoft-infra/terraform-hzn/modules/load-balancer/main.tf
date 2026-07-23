resource "hcloud_load_balancer" "this" {
  name               = var.lb_name
  load_balancer_type = var.lb_server_type
  location           = var.location
  delete_protection  = var.delete_rebuild_protection

  algorithm {
    type = var.lb_algorithm
  }

  labels = {
    env        = var.environment
    created_by = "jilani"
  }
}

resource "hcloud_load_balancer_network" "this" {
  load_balancer_id = hcloud_load_balancer.this.id
  network_id       = var.network_id
}

resource "hcloud_load_balancer_target" "this" {
  type             = "label_selector"
  load_balancer_id = hcloud_load_balancer.this.id
  label_selector   = var.server_labels
  use_private_ip   = true

  depends_on = [hcloud_load_balancer_network.this]
}

resource "hcloud_load_balancer_service" "https" {
  load_balancer_id = hcloud_load_balancer.this.id
  protocol         = "tcp"
  listen_port      = 80
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
  load_balancer_id = hcloud_load_balancer.this.id
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
