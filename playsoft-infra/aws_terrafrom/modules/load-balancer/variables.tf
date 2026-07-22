variable "project" {
  description = "Project tag / name prefix"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to create the ALB and its security group in"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs the ALB is deployed into"
  type        = list(string)
}

variable "app_nodeport" {
  description = "NodePort the ingress controller listens on (ALB forwards here)"
  type        = number
}
