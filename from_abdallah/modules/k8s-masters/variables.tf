variable "hcloud_token" {
  sensitive = true
}



#variable "ip" {
#  type = string
#}

variable "server_location" {
  type = string
}

variable "server_type" {
  type = string
}

#variable "ssh_key_name" {
#  description = "SSH key for the nodes"
#  type        = string
#}

#variable "network_id" {
#  description = "Private network ID"
#  type        = number
#}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

#variable "master_private_ip" {
#  description = "Private IP for the master node"
#  type        = string
#}

variable "worker_base_offset" {
  description = "IP offset in network for workers (e.g. 11 for 10.20.0.11)"
  type        = number
  default     = 11
}

variable "role_master_selector" {
  type    = string
  default = "role=k8s_master_and_worker,created_by=jilani"
}

variable "role_worker_selector" {
  type    = string
  default = "role=k8s_worker,created_by=jilani"
}

#variable "network_cidr" {
#  description = "Private network CIDR to calculate worker IPs"
#  type        = string
#}

variable "gateway_ip" {
  description = "Private network gateway IP"
  type        = string
}

variable "delete_rebuild_protection" {
  type = bool
}

variable "ssh_keys" {
  description = "List of SSH key names or IDs to attach to the server"
  type        = list(string)
}



variable "environment" {
  type = string
}



variable "server_name" {
  type = string
  default = "hzn-k8s-master"
}



