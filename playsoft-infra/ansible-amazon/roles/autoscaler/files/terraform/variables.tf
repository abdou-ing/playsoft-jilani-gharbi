variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

# {name: private_ip} -- the FULL set of autoscaler-managed workers this
# state should own after this apply (existing + new, or existing minus one
# for scale-in). Never includes the floor worker from the main aws_terrafrom
# state -- that's the whole point of this being a separate state. Written by
# webhook.py's apply_workers() as a tfvars.json file per-apply, not here.
variable "workers" {
  type    = map(string)
  default = {}
}

variable "ami_id" {
  type = string
}

variable "worker_instance_type" {
  type = string
}

variable "worker_root_volume_size" {
  type    = number
  default = 30
}

variable "ssh_key_name" {
  type = string
}

variable "private_subnet_id" {
  type = string
}

variable "worker_security_group_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "app_nodeport" {
  type = number
}

variable "master_endpoint" {
  description = "Master's private IP, passed to worker userdata"
  type        = string
}
