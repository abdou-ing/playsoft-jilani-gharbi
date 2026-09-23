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

  project            = var.project
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  admin_cidr         = var.admin_cidr
  ssh_key_name       = var.ssh_key_name
  cluster_role_name  = var.cluster_role_name

  node_role_name = var.node_role_name

  ebs_csi_role_arn       = var.ebs_csi_role_arn
  lb_controller_role_arn = var.lb_controller_role_arn
  node_instance_types    = var.node_instance_types
  node_desired_size      = var.node_desired_size
  node_min_size          = var.node_min_size
  node_max_size          = var.node_max_size
  node_disk_size         = var.node_disk_size

  depends_on = [module.network]
}

# ── Candidate target VMs on Proxmox (unchanged by the EKS migration) ─────
# WARNING: terraform/hetzner's own state (../hetzner) already manages
# ssh_server at vm_id 300 (its dev.tfvars has ssh_server_count = 1). This
# state (terraform/aws-eks) has no knowledge of that state. Applying both
# with ssh_server_count >= 1 in each WILL collide on the same Proxmox
# vm_id -- either `terraform import` VM 300 into this state and drop it
# from terraform/hetzner first, or keep ssh_server_count = 0 here until that
# migration happens. Do not apply with a non-zero count until that's
# resolved.
module "vnc_server" {
  count  = var.vnc_server_count
  source = "./modules/vnc-server"
  vm_id  = 600 + count.index

  node_name   = var.node_name
  template_id = var.template_id
}

module "ssh_server" {
  count  = var.ssh_server_count
  source = "./modules/ssh-server"
  vm_id  = 500 + count.index

  node_name   = var.node_name
  template_id = var.template_id
}
