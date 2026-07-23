variable "project" {
  description = "Project tag / name prefix"
  type        = string
}

variable "cluster_name" {
  description = "Cluster name (used as the kubernetes_cluster tag the aws_ec2 inventory filters on)"
  type        = string
}

variable "region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to create the worker security group in"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet the worker instance is pinned to"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB (for NodePort ingress rule)"
  type        = string
}

variable "master_security_group_id" {
  description = "Security group ID of the master (for kubelet/CNI ingress rules)"
  type        = string
}

variable "bastion_security_group_id" {
  description = "Security group ID of the bastion (for SSH ingress rule)"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN to register the worker instance with"
  type        = string
}

variable "app_nodeport" {
  description = "NodePort the target group attachment listens on"
  type        = number
}

variable "master_endpoint" {
  description = "Master's private IP, passed to worker userdata"
  type        = string
}

variable "worker_instance_type" {
  type = string
}

variable "worker_private_ip" {
  description = "Fixed private IP for the floor worker instance (must be inside private_subnet_id's CIDR)"
  type        = string
}

variable "worker_root_volume_size" {
  description = "Root EBS volume size in GB. AMI default (~8GB) isn't enough once Longhorn + the app's container images are on it."
  type        = number
  default     = 30
}

variable "ssh_key_name" {
  description = "EC2 key pair name for SSH (leave empty if using SSM only)"
  type        = string
}

variable "ami_id" {
  description = "AMI to use (leave empty to use the latest Ubuntu 24.04 for testing)"
  type        = string
}
