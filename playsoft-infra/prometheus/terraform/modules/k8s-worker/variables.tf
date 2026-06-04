variable "location" {
  type = string
}

variable "server_type" {
  type    = string
  default = "cx23"
}

variable "ssh_key_name" {
  type = string
}

variable "network_id" {
  type = number
}

variable "worker_count" {
  type    = number
  default = 1
}

variable "master_private_ip" {
  type = string
}

variable "network_cidr" {
  type = string
}

variable "gateway_ip" {
  type = string
}
