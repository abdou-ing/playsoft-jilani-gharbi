

data "hcloud_networks" "private_networks" {
  with_selector = "name=instalab_private_network,env=${var.environment}"
}

#data "hcloud_certificate" "totolabbyfr" {
#  with_selector = "name=${var.cert_name},env=${var.environment}"
#}





