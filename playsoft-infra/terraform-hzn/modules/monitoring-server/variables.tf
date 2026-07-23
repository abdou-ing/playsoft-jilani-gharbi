variable "location" {
  type = string
}

variable "server_type" {
  type = string
}

variable "ssh_key_name" {
  description = "Name of SSH key already uploaded in Hetzner"
  type        = string
}

variable "network_id" {
  type = string
}

variable "monitoring_private_ip" {
  type = string
}

variable "my_ip" {
  description = "IP address from environment"
  type        = string
}
