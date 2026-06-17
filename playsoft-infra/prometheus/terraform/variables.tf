variable "location" {
  default = "nbg1"
}

variable "server_type" {
  default = "cx23"
}

variable "ssh_keys" {
  description = "List of SSH key names or IDs"
  type        = list(string)
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "server_name" {
  type    = string
  default = "hzn-k8s-worker"
}

variable "workers" {
  description = "Map of worker name => private IP to create. Computed live by the autoscaler webhook from Hetzner discovery — never hand-edit this."
  type        = map(string)
  default     = {}
}

variable "gateway_ip" {
  type    = string
  default = "10.20.0.1"
}
