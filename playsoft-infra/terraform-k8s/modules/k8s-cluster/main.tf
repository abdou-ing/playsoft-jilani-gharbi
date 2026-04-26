# Master Server
resource "hcloud_server" "master" {
  name        = "hzn-k8s-master-jilani"
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
    ip         = var.master_private_ip
    alias_ips = []

  }

  user_data = file("${path.module}/../../cloud-init/master.yaml")

  labels = {
    role       = "master"
    created_by = "jilani"
  }
}

# Worker Servers
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
    ip         = cidrhost(var.network_cidr, var.worker_base_offset + count.index)
  }

  user_data = file("${path.module}/../../cloud-init/master.yaml")

  labels = {
    role       = "worker"
    created_by = "jilani"
  }
}
