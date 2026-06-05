# Set the variable value in *.tfvars file
# or using the -var="hcloud_token=..." CLI option
variable "hcloud_token" {
  sensitive = true
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















