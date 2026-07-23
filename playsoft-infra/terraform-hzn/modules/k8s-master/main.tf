resource "hcloud_server" "master" {
  count              = var.master_count
  name               = "${var.server_name}-${count.index + 1}-${var.environment}"
  image              = data.hcloud_image.k8s_snapshot.id
  server_type        = var.server_type
  location           = var.location
  delete_protection  = var.delete_rebuild_protection
  rebuild_protection = var.delete_rebuild_protection
  ssh_keys           = var.ssh_keys

  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }

  network {
    network_id = var.network_id
    ip         = cidrhost(var.network_cidr, var.master_base_offset + count.index)
    alias_ips  = []
  }

  user_data = templatefile("${path.module}/cloud-init.yml", {
    gateway_ip = var.gateway_ip
  })

  labels = {
    role       = "k8s-master"
    name       = var.server_name
    env        = var.environment
    location   = var.location
    created_by = "jilani"
  }
}
