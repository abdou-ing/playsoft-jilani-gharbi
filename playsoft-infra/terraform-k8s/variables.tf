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

variable "master_count" {
  description = "Number of k8s master nodes"
  type        = number
  default     = 1
}

variable "master_base_offset" {
  description = "Starting IP offset for masters (e.g. 10 → 10.20.0.10)"
  type        = number
  default     = 10
}

variable "worker_count" {
  description = "Number of k8s worker nodes"
  type        = number
  default     = 1
}

variable "worker_base_offset" {
  description = "Starting IP offset for workers (e.g. 3 → 10.20.0.3)"
  type        = number
  default     = 3
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

variable "proxmox_ssh_username" {
  description = "Linux user used by the Proxmox provider for SSH/SFTP operations such as snippet uploads"
  type        = string
}

variable "proxmox_ssh_private_key_path" {
  description = "Private key path used by the Proxmox provider for SSH/SFTP operations such as snippet uploads"
  type        = string
}

variable "node_name" {
  type = string
}

variable "template_id" {
  type = number
}

variable "private_network_cidr" {
  description = "Private network CIDR"
  type        = string
  default     = "10.20.0.0/24"
}

variable "gateway_ip" {
  description = "Private network gateway IP"
  type        = string
  default     = "10.20.0.1"
}

variable "network_name" {
  description = "Hetzner private network name"
  type        = string
  default     = "nw-jilani"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "delete_rebuild_protection" {
  description = "Enable delete and rebuild protection on the master node"
  type        = bool
  default     = false
}


variable "ssh_server_count" {
  description = "Number of SSH servers"
  type        = number
  default     = 0
}

variable "windows_server_count" {
  description = "Number of Windows servers"
  type        = number
  default     = 1
}

variable "windows_template_id" {
  description = "Template ID for Windows VM"
  type        = number
}
