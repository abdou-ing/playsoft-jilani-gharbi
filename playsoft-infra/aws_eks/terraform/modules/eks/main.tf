############################################
# Pre-created IAM roles, referenced by name only.
############################################
data "aws_caller_identity" "current" {}

locals {
  cluster_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_role_name}"
  node_role_arn    = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.node_role_name}"
}

############################################
# EKS cluster
############################################
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = local.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(var.public_subnet_ids, var.private_subnet_ids)
    endpoint_public_access  = true
    endpoint_private_access = true
    public_access_cidrs     = [var.admin_cidr]
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = { Name = "${var.project}-eks" }
}

############################################
# Optional node SSH access (admin_cidr-restricted), same posture as the
resource "aws_security_group" "node_ssh" {
  count       = var.ssh_key_name != "" ? 1 : 0
  name        = "${var.project}-sg-node-ssh"
  description = "SSH to EKS worker nodes from admin_cidr"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-sg-node-ssh" }
}

############################################
# Managed node group
############################################
resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.project}-default"
  node_role_arn   = local.node_role_arn
  subnet_ids      = var.private_subnet_ids

  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"
  instance_types = var.node_instance_types
  disk_size      = var.node_disk_size

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  dynamic "remote_access" {
    for_each = var.ssh_key_name != "" ? [1] : []
    content {
      ec2_ssh_key               = var.ssh_key_name
      source_security_group_ids = [aws_security_group.node_ssh[0].id]
    }
  }

  tags = { Name = "${var.project}-eks-node" }
}

############################################
# EKS addons
############################################
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "coredns"
  resolve_conflicts_on_update = "OVERWRITE"

  # CoreDNS pods need somewhere to schedule.
  depends_on = [aws_eks_node_group.default]
}

resource "aws_eks_addon" "ebs_csi" {
  count = var.ebs_csi_role_arn != "" ? 1 : 0

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = var.ebs_csi_role_arn
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.default]
}
