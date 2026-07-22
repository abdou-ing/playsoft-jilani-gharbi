############################################
# Bastion security group
#
# Public SSH jump box + Ansible runner. Inbound is limited to
# SSH from var.admin_cidr -- this is the single door into the
# private network, so lock that CIDR down to your own IP/32.
############################################
resource "aws_security_group" "bastion" {
  name        = "${var.project}-sg-bastion"
  description = "Bastion (SSH jump box + Ansible runner)"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description = "HTTP reverse proxy to the cluster (single-IP entry point)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-sg-bastion" }
}

############################################
# BASTION host (single EC2, public subnet + EIP)
#
# Serves two roles: SSH jump box into the private cluster, and
# the Ansible runner that discovers nodes and runs join/cleanup
# playbooks over their private IPs.
############################################
resource "aws_instance" "bastion" {
  ami                         = local.ami
  instance_type               = var.bastion_instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = var.ssh_key_name != "" ? var.ssh_key_name : null
  associate_public_ip_address = true

  user_data = base64encode(templatefile("${path.module}/userdata/bastion.sh", {
    alb_dns_name = var.alb_dns_name
  }))

  tags = {
    Name     = "${var.project}-bastion"
    k8s_role = "bastion"
  }
}

resource "aws_eip" "bastion" {
  domain   = "vpc"
  instance = aws_instance.bastion.id

  tags = { Name = "${var.project}-bastion-eip" }
}
