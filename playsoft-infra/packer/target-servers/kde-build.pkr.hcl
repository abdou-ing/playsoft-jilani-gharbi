build {
  name    = "KDE-image"
  sources = ["source.hcloud.bastion"]

  provisioner "shell" {
    script = "provisioners/provision.sh"
  }
}
