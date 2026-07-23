variable "project" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "cluster_role_name" {
  description = "Name of the pre-created IAM role for the EKS control plane (eks.amazonaws.com trust + AmazonEKSClusterPolicy) -- jilani can't create IAM roles and has no iam:GetRole either, only iam:PassRole on this role, so the ARN is built from the name + account ID rather than looked up. Abdallah provisions this one."
  type        = string
}

variable "node_role_name" {
  description = "Name of the pre-created IAM role for the managed node group (ec2.amazonaws.com trust + worker/CNI/ECR-readonly/SSM policies). Same reason as cluster_role_name."
  type        = string
}

variable "ebs_csi_role_arn" {
  description = "Pre-created IRSA role for the aws-ebs-csi-driver addon (needs this cluster's OIDC issuer, so it can only exist after the first apply). Leave empty to skip the addon on the first apply."
  type        = string
  default     = ""
}

variable "public_subnet_ids" {
  description = "Used for the ALB (internet-facing Ingress targets)"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Node group + EKS control plane ENIs live here"
  type        = list(string)
}

variable "admin_cidr" {
  description = "CIDR allowed to reach the public API endpoint and node SSH"
  type        = string
}

variable "ssh_key_name" {
  type    = string
  default = ""
}

variable "node_instance_types" {
  type = list(string)
}

variable "node_desired_size" {
  type = number
}

variable "node_min_size" {
  type = number
}

variable "node_max_size" {
  type = number
}

variable "node_disk_size" {
  type = number
}
