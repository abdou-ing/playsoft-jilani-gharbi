module "network" {
  source = "./modules/network"

  project              = var.project
  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "eks" {
  source = "./modules/eks"

  project             = var.project
  cluster_name        = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  vpc_id              = module.network.vpc_id
  public_subnet_ids   = module.network.public_subnet_ids
  private_subnet_ids  = module.network.private_subnet_ids
  admin_cidr          = var.admin_cidr
  ssh_key_name        = var.ssh_key_name
  cluster_role_name   = var.cluster_role_name
  node_role_name      = var.node_role_name
  ebs_csi_role_arn    = var.ebs_csi_role_arn
  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_disk_size      = var.node_disk_size

  depends_on = [module.network]
}
