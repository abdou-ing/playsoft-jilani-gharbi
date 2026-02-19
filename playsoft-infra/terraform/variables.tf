variable "location" {
  default = "nbg1"
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

variable "centos_private_ip" {
  description = "Private IP of the CentOS server"
  type        = string
  sensitive   = true
}

variable "my_ip" {
  description = "IP address from environment"
  type        = string
}

variable "server_count" {
  description = "Number of servers"
  default     = 1
}

