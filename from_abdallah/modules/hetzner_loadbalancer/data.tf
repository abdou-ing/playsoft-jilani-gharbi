

data "hcloud_networks" "private_networks" {
  count         = var.network_id == null ? 1 : 0
  with_selector = "name=${var.network_name},env=${var.environment}"
}

#data "hcloud_certificate" "totolabbyfr" {
#  with_selector = "name=${var.cert_name},env=${var.environment}"
#}





