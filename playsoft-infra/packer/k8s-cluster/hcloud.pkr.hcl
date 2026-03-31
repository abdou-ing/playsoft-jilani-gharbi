source "hcloud" "k8s_master" {
  token       = var.hcloud_token
  server_type = var.server_type
  image       = var.image
  ssh_username = "root"
  location     = var.location
  snapshot_name = var.snapshot_name_master
  snapshot_labels = var.snapshot_labels_master
}

source "hcloud" "k8s_worker" {
  token       = var.hcloud_token
  server_type = var.server_type
  image       = var.image
  ssh_username = "root"
  location     = var.location
  snapshot_name = var.snapshot_name_worker
  snapshot_labels = var.snapshot_labels_worker
}