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
  description = "VPC ID to create the master security group in"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet the master instance is pinned to"
  type        = string
}

variable "bastion_security_group_id" {
  description = "Security group ID of the bastion (for SSH/API ingress rules)"
  type        = string
}

variable "master_private_ip" {
  description = "Fixed private IP for the master instance (must be inside private_subnet_id's CIDR). Pinned so kubeadm join / --control-plane-endpoint stays valid even if the instance is replaced."
  type        = string
}

variable "master_instance_type" {
  type = string
}

variable "master_root_volume_size" {
  description = "Root EBS volume size in GB. AMI default (~8GB) is too small once etcd/containerd images/Calico are all on it."
  type        = number
  default     = 20
}

variable "ssh_key_name" {
  description = "EC2 key pair name for SSH (leave empty if using SSM only)"
  type        = string
}

variable "ami_id" {
  description = "AMI to use (leave empty to use the latest Ubuntu 24.04 for testing)"
  type        = string
}
