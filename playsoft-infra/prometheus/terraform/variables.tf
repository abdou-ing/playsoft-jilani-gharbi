variable "location" {
  default = "nbg1"
}

variable "server_type" {
  default = "cx23"
}

variable "ssh_key_name" {
  type = string
}

variable "k8s_master_private_ip" {
  type    = string
  default = "10.20.0.10"
}

variable "worker_count" {
  type    = number
  default = 1
}

variable "private_network_cidr" {
  type    = string
  default = "10.20.0.0/24"
}

variable "gateway_ip" {
  type    = string
  default = "10.20.0.1"
}
