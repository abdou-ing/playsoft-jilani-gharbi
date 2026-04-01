variable "hcloud_token" {
  type    = string
  default = env("HCLOUD_TOKEN")
}

variable "server_type" {
  type    = string
  default = "cx23"
}

variable "location" {
  type    = string
  default = "nbg1"
}

variable "image" {
  type    = string
  default = "ubuntu-24.04"
}

variable "snapshot_name" {
  type    = string
  default = "hzn-jilani-k8s-1.29-containerd-node-v1-{{timestamp}}"
}



variable "snapshot_labels" {
  type    = map(string)
  default = {
    "role"       = "k8s_master_and_worker"
    "created_by" = "jilani"
  }
}
