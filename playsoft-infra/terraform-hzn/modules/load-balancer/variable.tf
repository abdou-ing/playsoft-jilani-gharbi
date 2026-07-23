variable "lb_name" {
  description = "Name for the load balancer"
  type        = string
}

variable "location" {
  description = "Hetzner location (e.g. nbg1, fsn1, hel1)"
  type        = string
}

variable "lb_server_type" {
  description = "Load balancer type: lb11, lb21, lb31"
  type        = string
  default     = "lb11"
}

variable "lb_algorithm" {
  description = "Algorithm: round_robin or least_connections"
  type        = string
  default     = "round_robin"
}

variable "network_id" {
  description = "Hetzner network ID to attach the LB to"
  type        = number
}

variable "server_labels" {
  description = "Label selector for backend targets (e.g. role=k8s-worker,env=dev)"
  type        = string
}

variable "environment" {
  type = string
}

variable "delete_rebuild_protection" {
  type    = bool
  default = false
}
