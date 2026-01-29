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
  type = string
  sensitive = true
}

variable "network_id" {
  type = string
}
