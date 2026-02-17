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

variable "my_ip" {
  description = "IP address from environment"
  type        = string
}

variable "centos_private_ip" {
  description = "Private IP of the CentOS server"
  type        = string
}