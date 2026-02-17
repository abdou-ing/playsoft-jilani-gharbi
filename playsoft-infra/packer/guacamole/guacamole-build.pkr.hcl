build {
  name    = "guacamole-image"
  sources = ["source.hcloud.guacamole"]

  provisioner "shell" {
    script = "provisions/provision.sh"
  }
}
