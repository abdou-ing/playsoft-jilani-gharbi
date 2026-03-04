variable "proxmox_api_url" {}
variable "proxmox_api_token_id" {}
variable "proxmox_api_token_secret" {}

variable "node_name" {}
variable "template_name" {}
variable "vm_id" {
  type = number
  default = 201
}
