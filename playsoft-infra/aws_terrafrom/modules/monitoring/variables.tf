variable "project" {
  description = "Project tag / name prefix"
  type        = string
}

variable "cluster_name" {
  description = "Cluster name (used as the kubernetes_cluster tag the aws_ec2 inventory filters on)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to create the monitoring security group in"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID the monitoring instance is deployed into"
  type        = string
}

variable "admin_cidr" {
  description = "CIDR allowed to reach SSH/Grafana/Prometheus directly (use your IP as x.x.x.x/32 -- never 0.0.0.0/0)"
  type        = string
}

variable "monitoring_instance_type" {
  type    = string
  default = "t3.small"
}

variable "ssh_key_name" {
  description = "EC2 key pair name for SSH (leave empty if using SSM only)"
  type        = string
}

variable "ami_id" {
  description = "AMI to use (leave empty to use the latest Ubuntu 24.04 for testing)"
  type        = string
}
