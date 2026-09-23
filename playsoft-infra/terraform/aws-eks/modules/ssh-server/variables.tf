variable "node_name" {
  type = string
}

variable "vm_id" {
  type = number
}

variable "template_id" {
  type = number
}

variable "cloud_init_datastore_id" {
  type    = string
  default = "local"
}
