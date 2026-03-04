variable "node_name" {}
variable "vm_name" {}
variable "template_id" {}

variable "cpu" {}
variable "memory" {}

variable "disk_size" {
  type = number
}

variable "storage" {}
variable "bridge" {}
variable "vm_id" {
  type        = number
  description = "The VM ID to assign on Proxmox"
}

variable "ssh_public_key" {}
