source "hcloud" "bastion" {
  token        = var.hcloud_token
  image        = var.image
  server_type  = var.server_type
  location     = var.location
  ssh_username = var.ssh_username
  snapshot_name = var.snapshot_name
  snapshot_labels = var.snapshot_labels
}
