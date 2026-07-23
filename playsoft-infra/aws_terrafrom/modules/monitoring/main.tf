############################################
# Monitoring security group
#
# Prometheus (9090) and Grafana (3000) are admin surfaces, not public
# services -- reachable directly by the operator (restricted to
# admin_cidr), not proxied through the bastion. Mirrors
# terraform-hzn/modules/monitoring-server's firewall exactly.
############################################
resource "aws_security_group" "monitoring" {
  name        = "${var.project}-sg-monitoring"
  description = "Prometheus + Grafana (admin-only direct access)"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description = "Grafana from admin"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description = "Prometheus from admin"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-sg-monitoring" }
}

############################################
# Monitoring host (single EC2, public subnet + EIP)
#
# Runs Prometheus + Grafana (ansible-amazon/roles/prometheus,
# roles/grafana). Deliberately separate from the bastion, which also
# runs the autoscaler webhook -- an autoscaler bug shouldn't be able
# to take monitoring down, and vice versa.
############################################
resource "aws_instance" "monitoring" {
  ami                         = local.ami
  instance_type               = var.monitoring_instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.monitoring.id]
  key_name                    = var.ssh_key_name != "" ? var.ssh_key_name : null
  associate_public_ip_address = true

  tags = {
    Name               = "${var.project}-monitoring"
    k8s_role           = "monitoring"
    kubernetes_cluster = var.cluster_name
    created_by         = "jilani"
  }
}

resource "aws_eip" "monitoring" {
  domain   = "vpc"
  instance = aws_instance.monitoring.id

  tags = { Name = "${var.project}-monitoring-eip" }
}
