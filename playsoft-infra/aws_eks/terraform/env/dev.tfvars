region       = "us-east-1"
project      = "jilani-k8s-eks"
cluster_name = "guacamole"

kubernetes_version = "1.31"

vpc_cidr             = "10.30.0.0/16"
azs                  = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.30.0.0/24", "10.30.1.0/24"]
private_subnet_cidrs = ["10.30.10.0/24", "10.30.11.0/24"]

admin_cidr = "0.0.0.0/0"

ssh_key_name = "key-name"

cluster_role_name = ""
node_role_name    = ""


ebs_csi_role_arn       = ""
lb_controller_role_arn = ""

node_instance_types = ["t3.large"]
node_desired_size   = 2
node_min_size       = 2
node_max_size       = 4
node_disk_size      = 40
