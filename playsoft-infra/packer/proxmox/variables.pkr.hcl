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

variable "proxmox_node" {
  type    = string
}

variable "source_template_id" {
  type    = number
  default = 110
}

variable "new_template_id" {
  type    = number
  default = 200
}

variable "new_template_name" {
  type    = string
  default = "kali-vnc"
}

variable "ssh_user" {
  type    = string
  default = "bob"
}

variable "ssh_password" {
  type      = string
  sensitive = true
}
