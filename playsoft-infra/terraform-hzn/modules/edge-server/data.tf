data "hcloud_image" "bastion_snapshot" {
  with_selector = "created_by=jilani,role=bastion"
  most_recent   = true
}