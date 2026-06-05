data "hcloud_image" "k8s_snapshot" {
  with_selector = "name=hzn-k8s,env=${var.environment}"
  most_recent   = true
}

data "hcloud_networks" "private_networks" {
  with_selector = "name=instalab_private_network,env=${var.environment}"
}
