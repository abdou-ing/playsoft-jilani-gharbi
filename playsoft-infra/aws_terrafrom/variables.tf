variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-central-1"
}

variable "project" {
  description = "Project tag / name prefix"
  type        = string
  default     = "k8s-selfmanaged"
}

variable "cluster_name" {
  description = "Cluster name (used as the kubernetes_cluster tag the aws_ec2 inventory filters on)"
  type        = string
  default     = "my-cluster"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread across"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (one per AZ)"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs (one per AZ)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "ami_id" {
  description = "AMI with kubeadm/kubelet/containerd pre-baked (leave empty to use the latest Ubuntu 24.04 for testing)"
  type        = string
  default     = ""
}

variable "master_private_ip" {
  description = "Fixed private IP for the single master instance (must be inside private_subnet_cidrs[0]). This is a single-master control plane with no etcd clustering / HA join flow implemented, so there's no load balancer in front of it -- pinning the IP is what keeps kubeadm join / --control-plane-endpoint valid across a terraform apply-driven replace."
  type        = string
}

variable "master_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "worker_instance_type" {
  type    = string
  default = "t3.large"
}

variable "bastion_instance_type" {
  type    = string
  default = "t3.small"
}

variable "admin_cidr" {
  description = "CIDR allowed to SSH the bastion (use your IP as x.x.x.x/32 -- never 0.0.0.0/0). No default: you must set this explicitly."
  type        = string
}

variable "worker_min_size" {
  type    = number
  default = 3
}

variable "worker_max_size" {
  type    = number
  default = 6
}

variable "worker_desired_capacity" {
  type    = number
  default = 3
}

variable "ssh_key_name" {
  description = "Name of a pre-existing EC2 key pair in AWS to use for SSH (leave empty for none)"
  type        = string
  default     = ""
}

variable "app_nodeport" {
  description = "NodePort the ingress controller listens on (ALB forwards here)"
  type        = number
  default     = 30080
}
