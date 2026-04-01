source "hcloud" "k8s_template" {
  token       = var.hcloud_token
  server_type = var.server_type
  image       = var.image
  ssh_username = "root"
  location     = var.location
  snapshot_name = var.snapshot_name
  snapshot_labels = var.snapshot_labels
}