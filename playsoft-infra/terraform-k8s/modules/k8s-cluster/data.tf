data "hcloud_image" "k8s_snapshot" {
  with_selector = "created_by=jilani,role=k8s_master_and_worker"
  most_recent   = true
}
