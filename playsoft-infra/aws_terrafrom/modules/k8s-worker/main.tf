############################################
# Worker security group
############################################
resource "aws_security_group" "worker" {
  name        = "${var.project}-sg-worker"
  description = "Kubernetes workers"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.project}-sg-worker" }
}

resource "aws_security_group_rule" "worker_nodeport_from_alb" {
  description              = "NodePort range from ALB"
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = var.alb_security_group_id
}

resource "aws_security_group_rule" "worker_kubelet_from_master" {
  description              = "kubelet 10250 from master"
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = var.master_security_group_id
}

resource "aws_security_group_rule" "worker_pod_traffic_self" {
  description       = "All node/pod (CNI) traffic between workers"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.worker.id
  self              = true
}

resource "aws_security_group_rule" "worker_pod_traffic_from_master" {
  description              = "All node/pod (CNI) traffic from master"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = var.master_security_group_id
}

resource "aws_security_group_rule" "worker_ssh_from_bastion" {
  description              = "SSH from bastion"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = var.bastion_security_group_id
}

resource "aws_security_group_rule" "worker_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.worker.id
}

############################################
# WORKER instance (floor)
#
# A single, non-ASG instance pinned to a fixed private IP -- mirrors
# modules/k8s-master exactly, same reasoning: this is the always-on
# "floor" of the worker pool. Extra workers that the CPU-based
# autoscaler adds/removes on top of this live in a separate,
# bastion-staged Terraform state (own for_each over a workers map) so
# scale-in can never touch this instance even by accident -- see
# ansible-amazon/roles/autoscaler.
############################################
resource "aws_instance" "worker" {
  ami           = local.ami
  instance_type = var.worker_instance_type
  key_name      = var.ssh_key_name != "" ? var.ssh_key_name : null

  subnet_id              = var.private_subnet_id
  private_ip             = var.worker_private_ip
  vpc_security_group_ids = [aws_security_group.worker.id]

  root_block_device {
    volume_size           = var.worker_root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = base64encode(templatefile("${path.module}/userdata/worker.sh", {
    master_endpoint = var.master_endpoint
    region          = var.region
    cluster_name    = var.cluster_name
  }))

  tags = {
    Name               = "${var.project}-worker-1"
    k8s_role           = "worker"
    kubernetes_cluster = var.cluster_name
    created_by         = "jilani"
  }
}

# Registers the floor worker with the ALB target group. Extra
# autoscaler-added workers get their own attachment inside the staged
# Terraform config on the bastion -- not here, since that state is
# what actually creates those instances.
resource "aws_lb_target_group_attachment" "worker" {
  target_group_arn = var.target_group_arn
  target_id        = aws_instance.worker.id
  port             = var.app_nodeport
}
