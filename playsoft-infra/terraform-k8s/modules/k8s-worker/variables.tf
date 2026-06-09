variable "location" {
  type = string
}

variable "server_type" {
  type    = string
  default = "cx23"
}

variable "server_name" {
  type    = string
  default = "hzn-k8s-worker"
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

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 1
}

variable "worker_base_offset" {
  description = "Starting IP offset for workers (e.g. 20 → 10.20.0.20)"
  type        = number
  default     = 20
}

variable "network_cidr" {
  description = "Private network CIDR used to calculate node IPs"
  type        = string
}

variable "gateway_ip" {
  description = "Private network gateway IP"
  type        = string
}
