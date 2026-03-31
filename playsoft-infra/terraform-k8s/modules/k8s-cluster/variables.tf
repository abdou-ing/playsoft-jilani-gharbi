variable "location" {
  description = "Region for the cluster"
  type        = string
}

variable "server_type" {
  description = "HCloud server type"
  type        = string
  default     = "cx23"
}

variable "ssh_key_name" {
  description = "SSH key for the nodes"
  type        = string
}

variable "network_id" {
  description = "Private network ID"
  type        = number
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "master_private_ip" {
  description = "Private IP for the master node"
  type        = string
}

variable "worker_base_offset" {
  description = "IP offset in network for workers (e.g. 11 for 10.20.0.11)"
  type        = number
  default     = 11
}

variable "role_master_selector" {
  type    = string
  default = "role=k8s_master,created_by=jilani"
}

variable "role_worker_selector" {
  type    = string
  default = "role=k8s_worker,created_by=jilani"
}

variable "network_cidr" {
  description = "Private network CIDR to calculate worker IPs"
  type        = string
  default     = "10.20.0.0/24"
}
