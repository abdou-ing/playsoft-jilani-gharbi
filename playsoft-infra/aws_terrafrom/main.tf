# The "jilani" key pair already exists in AWS -- reference it by name
# instead of trying to (re)import it via aws_key_pair.
module "network" {
  source = "./modules/network"

  project              = var.project
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "load_balancer" {
  source = "./modules/load-balancer"

  project           = var.project
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  app_nodeport      = var.app_nodeport
}

module "bastion" {
  source = "./modules/bastion"

  project               = var.project
  vpc_id                = module.network.vpc_id
  public_subnet_id      = module.network.public_subnet_ids[0]
  admin_cidr            = var.admin_cidr
  bastion_instance_type = var.bastion_instance_type
  ssh_key_name          = var.ssh_key_name
  ami_id                = var.ami_id
  alb_dns_name          = module.load_balancer.alb_dns_name
}

module "k8s_master" {
  source = "./modules/k8s-master"

  project                   = var.project
  cluster_name              = var.cluster_name
  region                    = var.region
  vpc_id                    = module.network.vpc_id
  private_subnet_id         = module.network.private_subnet_ids[0]
  bastion_security_group_id = module.bastion.security_group_id
  master_private_ip         = var.master_private_ip
  master_instance_type      = var.master_instance_type
  ssh_key_name              = var.ssh_key_name
  ami_id                    = var.ami_id
}

module "monitoring" {
  source = "./modules/monitoring"

  project                  = var.project
  cluster_name             = var.cluster_name
  vpc_id                   = module.network.vpc_id
  public_subnet_id         = module.network.public_subnet_ids[0]
  admin_cidr               = var.admin_cidr
  ssh_key_name             = var.ssh_key_name
  ami_id                   = var.ami_id
  monitoring_instance_type = var.monitoring_instance_type
}

module "k8s_worker" {
  source = "./modules/k8s-worker"

  project                   = var.project
  cluster_name              = var.cluster_name
  region                    = var.region
  vpc_id                    = module.network.vpc_id
  private_subnet_id         = module.network.private_subnet_ids[0]
  alb_security_group_id     = module.load_balancer.security_group_id
  master_security_group_id  = module.k8s_master.security_group_id
  bastion_security_group_id = module.bastion.security_group_id
  target_group_arn          = module.load_balancer.target_group_arn
  app_nodeport              = var.app_nodeport
  master_endpoint           = module.k8s_master.private_ip
  worker_instance_type      = var.worker_instance_type
  worker_private_ip         = var.worker_private_ip
  ssh_key_name              = var.ssh_key_name
  ami_id                    = var.ami_id
}

############################################
# Master <- Worker security group rules
#
# These close the other half of the master/worker traffic loop.
# They live here (not inside modules/k8s-master) because the
# worker module doesn't exist yet at the point k8s_master is
# created -- a module can't depend on another module's output
# while that module also depends on its output.
############################################
resource "aws_security_group_rule" "master_api_from_workers" {
  description              = "kube-apiserver 6443 from workers"
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  security_group_id        = module.k8s_master.security_group_id
  source_security_group_id = module.k8s_worker.security_group_id
}

resource "aws_security_group_rule" "master_kubelet_from_workers" {
  description              = "kubelet 10250 from workers"
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = module.k8s_master.security_group_id
  source_security_group_id = module.k8s_worker.security_group_id
}

resource "aws_security_group_rule" "master_pod_traffic_from_workers" {
  description              = "All node/pod (CNI) traffic from workers"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = module.k8s_master.security_group_id
  source_security_group_id = module.k8s_worker.security_group_id
}

############################################
# Monitoring -> master/worker node_exporter scrape rules
#
# node_exporter (:9100) is already installed by both userdata scripts,
# but nothing has ever opened the port -- Prometheus scrapes would
# time out silently without these. Same reason as the rules above:
# the monitoring module doesn't exist yet at the point k8s-master/
# k8s-worker are created.
############################################
resource "aws_security_group_rule" "master_node_exporter_from_monitoring" {
  description              = "node_exporter 9100 from monitoring"
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  security_group_id        = module.k8s_master.security_group_id
  source_security_group_id = module.monitoring.security_group_id
}

resource "aws_security_group_rule" "worker_node_exporter_from_monitoring" {
  description              = "node_exporter 9100 from monitoring"
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  security_group_id        = module.k8s_worker.security_group_id
  source_security_group_id = module.monitoring.security_group_id
}
