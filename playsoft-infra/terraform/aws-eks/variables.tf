variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project tag / name prefix"
  type        = string
  default     = "jilani-k8s-eks"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "guacamole"
}

variable "kubernetes_version" {
  description = "EKS control plane version. Check `aws eks describe-cluster-versions` for what's currently supported before applying -- this default may have aged out."
  type        = string
  default     = "1.31"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  type        = string
  default     = "10.30.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread across (EKS requires subnets in at least 2)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (one per AZ) -- ALB + NAT gateway live here"
  type        = list(string)
  default     = ["10.30.0.0/24", "10.30.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs (one per AZ) -- worker nodes live here"
  type        = list(string)
  default     = ["10.30.10.0/24", "10.30.11.0/24"]
}

variable "admin_cidr" {
  description = "CIDR allowed to reach the EKS public API endpoint and node SSH (use your own IP as x.x.x.x/32 -- never 0.0.0.0/0)"
  type        = string
}

# ── Pre-created IAM roles ────────────────────────────────────────────────
# jilani is deliberately denied iam:CreateRole/CreatePolicy/AttachRolePolicy/
# CreateOpenIDConnectProvider (separation-of-duties boundary held by
# Referenced by name (data "aws_iam_role" lookup in the eks module) rather
# than by ARN, since jilani only has iam:GetRole, not the ARN handed to him
# directly.
#
# cluster_role_name/node_role_name have no dependency on the cluster
# existing -- ask for those first. ebs_csi_role_arn/lb_controller_role_arn
# need this cluster's real OIDC issuer URL in their trust policy, so they
# can only be created (and only need to be filled in here) after the first
# apply -- leave them empty until then.

variable "cluster_role_name" {
  description = "Name of the pre-created EKS cluster IAM role"
  type        = string
}

variable "node_role_name" {
  description = "Name of the pre-created node group IAM role"
  type        = string
}

variable "ebs_csi_role_arn" {
  description = "Pre-created EBS CSI driver IRSA role ARN (empty until the cluster's OIDC issuer exists)"
  type        = string
  default     = ""
}

variable "lb_controller_role_arn" {
  description = "Pre-created AWS Load Balancer Controller IRSA role ARN (empty until the cluster's OIDC issuer exists). Only consumed by deploy.sh's helm install, not by any Terraform resource here."
  type        = string
  default     = ""
}

variable "ssh_key_name" {
  description = "EC2 key pair name for node SSH access (leave empty to disable remote access on the node group)"
  type        = string
  default     = ""
}

variable "node_instance_types" {
  description = "Instance types for the managed node group"
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "node_disk_size" {
  description = "Root EBS volume size (GiB) for worker nodes"
  type        = number
  default     = 40
}

# ── Proxmox (candidate target VMs, ported from terraform/hetzner) ───────────
# The Guacamole migration to EKS didn't move these -- ssh-server/vnc-server
# still provision on the same physical Proxmox host as before. See the
# collision warning above modules "ssh_server"/"vnc_server" in main.tf
# before applying: terraform/hetzner's own state may already own vm_id 300.
# Proxmox inputs are intentionally disabled until candidate VMs are needed.
variable "proxmox_api_url" {
  type = string
}
#
variable "proxmox_api_token_id" {
  type = string
}
#
variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}
#
variable "proxmox_ssh_username" {
  description = "Linux user used by the Proxmox provider for SSH/SFTP operations such as snippet uploads"
  type        = string
}
#
variable "proxmox_ssh_private_key_path" {
  description = "Private key path used by the Proxmox provider for SSH/SFTP operations such as snippet uploads"
  type        = string
}
#
variable "node_name" {
  description = "Proxmox node name"
  type        = string
}
#
variable "template_id" {
  description = "Proxmox VM template ID to clone from"
  type        = number
}
#
variable "vnc_server_count" {
  description = "Number of VNC candidate servers"
  type        = number
  default     = 0
}
#
variable "ssh_server_count" {
  description = "Number of SSH candidate servers"
  type        = number
  default     = 0
}
