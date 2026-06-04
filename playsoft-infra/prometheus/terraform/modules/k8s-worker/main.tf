data "hcloud_image" "k8s_snapshot" {
  with_selector = "created_by=jilani,role=k8s_master_and_worker"
  most_recent   = true
}

resource "hcloud_server" "worker" {
  count       = var.worker_count
  name        = "hzn-k8s-worker-${count.index + 1}-jilani"
  image       = data.hcloud_image.k8s_snapshot.id
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [var.ssh_key_name]

  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }

  network {
    network_id = var.network_id
    ip         = cidrhost(var.network_cidr, 11 + count.index)
  }

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    gateway_ip = var.gateway_ip
  })

  labels = {
    role       = "worker"
    created_by = "jilani"
  }
}
