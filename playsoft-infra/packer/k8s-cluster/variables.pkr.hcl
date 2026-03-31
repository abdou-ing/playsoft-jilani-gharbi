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

variable "snapshot_name_master" {
  type    = string
  default = "k8s-master-{{timestamp}}"
}

variable "snapshot_name_worker" {
  type    = string
  default = "k8s-worker-{{timestamp}}"
}

variable "snapshot_labels_master" {
  type    = map(string)
  default = {
    "role"       = "k8s_master"
    "created_by" = "jilani"
  }
}

variable "snapshot_labels_worker" {
  type    = map(string)
  default = {
    "role"       = "k8s_worker"
    "created_by" = "jilani"
  }
}