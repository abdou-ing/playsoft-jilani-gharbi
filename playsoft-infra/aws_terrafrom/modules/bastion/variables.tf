variable "project" {
  description = "Project tag / name prefix"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to create the bastion and its security group in"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID the bastion is deployed into"
  type        = string
}

variable "admin_cidr" {
  description = "CIDR allowed to SSH the bastion (use your IP as x.x.x.x/32 -- never 0.0.0.0/0)"
  type        = string
}

variable "bastion_instance_type" {
  type = string
}

variable "ssh_key_name" {
  description = "EC2 key pair name for SSH (leave empty if using SSM only)"
  type        = string
}

variable "ami_id" {
  description = "AMI to use (leave empty to use the latest Ubuntu 24.04 for testing)"
  type        = string
}

variable "alb_dns_name" {
  description = "Public DNS name of the app ALB, proxied through the bastion's nginx reverse proxy"
  type        = string
}
