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

variable "ssh_public_key" {}