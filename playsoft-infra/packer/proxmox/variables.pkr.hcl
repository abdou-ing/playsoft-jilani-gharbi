variable "proxmox_api_url" {
  type = string
}

variable "proxmox_username" {
  type = string
  default = "username on proxmox"
}

variable "proxmox_token" {
  type      = string
  sensitive = true
}

variable "ssh_username" {
  type    = string
  default = "ssh username to access Proxmox and the VM"
}


variable "proxmox_node" {
  type = string
}

variable "source_vm_id" {
  type = number
}

variable "new_vm_id" {
  type = number
}

variable "template_name" {
  type = string
}

variable "cpu_cores" {
  type = number
}

variable "memory" {
  type = number
}

variable "disk_size" {
  type = string
}
