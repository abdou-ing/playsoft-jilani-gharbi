variable "location" {
  type = string
}

variable "server_type" {
  type    = string
  default = "cx23"
}

variable "server_name" {
  type    = string
  default = "hzn-k8s-master"
}

variable "environment" {
  type = string
}

variable "ssh_keys" {
  description = "List of SSH key names or IDs to attach to the server"
  type        = list(string)
}

variable "network_id" {
  description = "Hetzner private network ID"
  type        = number
}

variable "master_count" {
  description = "Number of master nodes"
  type        = number
  default     = 1
}

variable "master_base_offset" {
  description = "Starting IP offset for masters (e.g. 10 → 10.20.0.10)"
  type        = number
  default     = 10
}

variable "network_cidr" {
  description = "Private network CIDR used to calculate node IPs"
  type        = string
}

variable "gateway_ip" {
  description = "Private network gateway IP"
  type        = string
}

variable "delete_rebuild_protection" {
  type    = bool
  default = false
}
