variable "location" {
  default = "fsn1"
}

variable "server_type" {
  default = "cx33"
}

variable "ssh_key_name" {
  description = "Name of SSH key already uploaded in Hetzner"
  type        = string
}

variable "k8s_master_private_ip" {
  description = "Private IP of the k8s master node"
  type        = string
  default     = "10.20.0.10"
}

variable "worker_count" {
  description = "Number of k8s worker nodes"
  type        = number
  default     = 1
}

variable "my_ip" {
  description = "IP address from environment"
  type        = string
}

variable "edge_private_ip" {
  description = "Private IP of the edge/bastion gateway"
  type        = string
  default     = "10.20.0.2"
}

variable "vnc_server_count" {
  description = "Number of VNC servers"
  type        = number
}

variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "node_name" {
  type    = string
}

variable "template_id" {
  type    = number
}
