variable "location" {
  default = "hel1"
}

variable "server_type" {
  default = "cx23"
}

variable "ssh_key_name" {
  description = "Name of SSH key already uploaded in Hetzner"
  type        = string
}

variable "edge_private_ip" {
  description = "Private IP of the edge gateway"
  type        = string
  sensitive   = true
}

variable "guacamole_private_ip" {
  description = "Private IP of the Guacamole server"
  type        = string
  sensitive   = true
}
