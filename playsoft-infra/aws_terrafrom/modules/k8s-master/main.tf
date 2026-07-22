############################################
# Master security group
#
# Rules that reference the worker security group (allow from
# workers on 6443/10250/all-CNI-traffic) live at the root module
# instead of here, since the worker module is created after this
# one and needs this module's security_group_id as an input --
# a module can't also depend on that module's output in return.
############################################
resource "aws_security_group" "master" {
  name        = "${var.project}-sg-master"
  description = "Kubernetes control plane"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.project}-sg-master" }
}

resource "aws_security_group_rule" "master_api_from_bastion" {
  description              = "kube-apiserver 6443 from bastion"
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.master.id
  source_security_group_id = var.bastion_security_group_id
}

resource "aws_security_group_rule" "master_etcd_self" {
  description       = "etcd peer/client 2379-2380 within control plane"
  type              = "ingress"
  from_port         = 2379
  to_port           = 2380
  protocol          = "tcp"
  security_group_id = aws_security_group.master.id
  self              = true
}

resource "aws_security_group_rule" "master_ssh_from_bastion" {
  description              = "SSH from bastion"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.master.id
  source_security_group_id = var.bastion_security_group_id
}

resource "aws_security_group_rule" "master_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.master.id
}

############################################
# Master instance
#
# A single, non-ASG instance pinned to a fixed private IP
# (var.master_private_ip). master_count is hard-locked to 1 (no
# etcd clustering / HA join flow implemented -- see root
# variables.tf), and the root volume below isn't set up to survive
# a replacement with /var/lib/etcd intact either, so an ASG here
# would add replacement complexity without real HA benefit. Pinning
# the private IP keeps kubeadm join / --control-plane-endpoint
# valid even across a `terraform apply`-driven replace, with no
# load balancer and no instance IAM role required.
############################################
resource "aws_instance" "master" {
  ami           = local.ami
  instance_type = var.master_instance_type
  key_name      = var.ssh_key_name != "" ? var.ssh_key_name : null

  subnet_id              = var.private_subnet_id
  private_ip             = var.master_private_ip
  vpc_security_group_ids = [aws_security_group.master.id]

  root_block_device {
    volume_size           = var.master_root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # Your master script is rendered with these variables available.
  user_data = base64encode(templatefile("${path.module}/userdata/master.sh", {
    master_endpoint = var.master_private_ip
    region          = var.region
    cluster_name    = var.cluster_name
  }))

  tags = {
    Name               = "${var.project}-master"
    k8s_role           = "master"
    kubernetes_cluster = var.cluster_name
    created_by         = "jilani"
  }
}
