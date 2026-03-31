build {
  name    = "k8s-master"
  sources = ["source.hcloud.k8s_master"]

  provisioner "shell" {
    script = "provisions/provision.sh"
  }

  # post-processor "hcloud-snapshot" {
  #   snapshot_name = var.snapshot_name_master
  # }
}

build {
  name    = "k8s-worker"
  sources = ["source.hcloud.k8s_worker"]

  provisioner "shell" {
    script = "provisions/provision.sh"
  }

  # post-processor "hcloud-snapshot" {
  #   snapshot_name = var.snapshot_name_worker
  # }
}