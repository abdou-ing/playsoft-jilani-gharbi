region       = "us-east-1"
project      = "jilani-k8s-selfmanaged"
cluster_name = "guacamole"

vpc_cidr = "10.20.0.0/16"


azs                  = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.20.0.0/24", "10.20.1.0/24"]
private_subnet_cidrs = ["10.20.10.0/24"]

ami_id = ""

master_private_ip = "10.20.10.10"
# Floor worker only -- the autoscaler adds/removes extra workers starting at
# .20 (see ansible-amazon/roles/autoscaler), matching the Hetzner project's
# own WORKER_BASE_IP convention so the two ranges never collide.
worker_private_ip = "10.20.10.20"

master_instance_type     = "t3.medium"
worker_instance_type     = "t3.large"
bastion_instance_type    = "t3.small"
monitoring_instance_type = "t3.small"

admin_cidr = "102.152.223.129/32"


ssh_key_name = "jilani"

app_nodeport = 30080
