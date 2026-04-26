packer {
  required_plugins {
    hcloud = {
      source  = "github.com/hashicorp/hcloud"
      version = ">= 1.4.0"
    }
  }
}