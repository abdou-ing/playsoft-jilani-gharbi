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
# WORKER launch template
############################################
resource "aws_launch_template" "worker" {
  name_prefix   = "${var.project}-worker-"
  image_id      = local.ami
  instance_type = var.worker_instance_type
  key_name      = var.ssh_key_name != "" ? var.ssh_key_name : null

  vpc_security_group_ids = [aws_security_group.worker.id]

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = var.worker_root_volume_size
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/userdata/worker.sh", {
    master_endpoint = var.master_endpoint
    region          = var.region
    cluster_name    = var.cluster_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name     = "${var.project}-worker"
      k8s_role = "worker"
    }
  }

  lifecycle { create_before_destroy = true }
}

############################################
# WORKER ASG  (min=3, scales out; across all AZs)
############################################
resource "aws_autoscaling_group" "worker" {
  name                = "${var.project}-worker-asg"
  min_size            = var.worker_min_size
  max_size            = var.worker_max_size
  desired_capacity    = var.worker_desired_capacity
  vpc_zone_identifier = var.private_subnet_ids

  # Register workers with the ALB target group automatically
  target_group_arns = [var.target_group_arn]

  launch_template {
    id      = aws_launch_template.worker.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.project}-worker"
    propagate_at_launch = true
  }
  tag {
    key                 = "k8s_role"
    value               = "worker"
    propagate_at_launch = true
  }
  tag {
    key                 = "kubernetes_cluster"
    value               = var.cluster_name
    propagate_at_launch = true
  }
  tag {
    key                 = "created_by"
    value               = "jilani"
    propagate_at_launch = true
  }
}

# Resolves the worker ASG's live instances so we can output their IPs.
data "aws_instances" "worker" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.worker.name]
  }
  instance_state_names = ["pending", "running"]

  depends_on = [aws_autoscaling_group.worker]
}
