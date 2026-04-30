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

variable "edge_private_ip" {
  type      = string
  sensitive = true
}

variable "network_id" {
  type = string
}

variable "my_ip" {
  description = "IP address from environment"
  type        = string
}

variable "private_network_cidr" {
  description = "Private network CIDR for MASQUERADE"
  type        = string
}