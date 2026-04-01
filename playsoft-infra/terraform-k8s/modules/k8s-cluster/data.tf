# Image retrieval
data "hcloud_image" "master_snapshot" {
  with_selector = var.role_master_selector
  most_recent   = true
}

data "hcloud_image" "worker_snapshot" {
  with_selector = var.role_worker_selector
  most_recent   = true
}
