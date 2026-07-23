variable "project" {
  description = "Project tag / name prefix"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name -- stamped onto subnets as kubernetes.io/cluster/<name> so the AWS Load Balancer Controller and cluster-autoscaler can discover them"
  type        = string
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}
