terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.59.0"
    }
  }
}

provider "hcloud" {
  # token read from HCLOUD_TOKEN env var
}
