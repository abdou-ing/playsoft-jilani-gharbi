source "hcloud" "bastion" {
  token        = var.hcloud_token
  image        = var.image
  server_type  = var.server_type
  location     = var.location
  ssh_username = "root"

  snapshot_name   = local.snapshot_name
  snapshot_labels = local.snapshot_labels
}