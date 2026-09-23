terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # Proxmox is intentionally disabled until candidate VMs are needed.
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.50"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project            = var.project
      kubernetes_cluster = var.cluster_name
      created_by         = "jilani"
    }
  }
}

# Same Proxmox account/token as terraform/hetzner -- the candidate target VMs
# (ssh-server/vnc-server modules below) live on that same physical host
# regardless of where Guacamole itself runs.
provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = true
  #
  ssh {
    username    = var.proxmox_ssh_username
    private_key = file(pathexpand(var.proxmox_ssh_private_key_path))
  }
}
