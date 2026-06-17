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

variable "workers" {
  description = "Map of worker name => private IP to create. Computed by the autoscaler webhook from live Hetzner discovery, so this module never has to guess offsets."
  type        = map(string)
  default     = {}
}

variable "gateway_ip" {
  description = "Private network gateway IP"
  type        = string
}
