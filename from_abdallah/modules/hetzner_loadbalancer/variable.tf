# Set the variable value in *.tfvars file
# or using the -var="hcloud_token=..." CLI option
variable "hcloud_token" {
  sensitive = true
  default   = ""
}

variable "lb_name" {
  description = "Name for the load balancer"
  type        = string
  default     = "instalab-load-balancer"
}

variable "network_id" {
  description = "Direct Hetzner network ID. If provided, skips label-based network lookup."
  type        = number
  default     = null
}

variable "network_name" {
  description = "Network label selector name (used only when network_id is null)"
  type        = string
  default     = "instalab_private_network"
}

variable "listen_port" {
  description = "Port the load balancer listens on"
  type        = number
  default     = 80
}

variable "destination_port" {
  description = "Backend port traffic is forwarded to"
  type        = number
  default     = 30080
}

variable "lb_location" {
  description = "The Hetzner LoadBalancer location for the resources. Must be one of: nbg1, fsn1, hel1."
  type        = string
}

variable "lb_server_type" {
  description = "The Hetzner LoadBalancer server type. Must be one of: lb11, lb21, lb31."
  type        = string
}

variable "lb_type" {
  description = "The Hetzner LoadBalancer algorithm type. Must be one of: round_robin, least_connections."
  type        = string
}

#variable "cert_domain_names" {
#  description = "List of domain names for the managed certificate"
#  type        = list(string)
#}

variable "server_labels" {
  description = "Selectors of target servers to be attached to Hetzner LoadBalancer"
  type        = string
}

#variable "cert_name" {
#  description = "Name of the managed certificate"
#  type        = string
#}

variable "environment" {
  type = string
}

#variable "loadbalancer_private_ip" {
#  description = "Private IP associated to the LB"
#  type        = string
#}

variable "delete_rebuild_protection" {
  type = bool
}















