variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "image" {
  type    = string
  default = "ubuntu-24.04"
}

variable "server_type" {
  type    = string
  default = "cx23"
}

variable "location" {
  type    = string
  default = "hel1"
}

variable "ssh_username" {
  type    = string
  default = "root"
}

variable "snapshot_name" {
  type    = string
  default = "hzn-guacamole-jilani-snap{{timestamp}}"
}