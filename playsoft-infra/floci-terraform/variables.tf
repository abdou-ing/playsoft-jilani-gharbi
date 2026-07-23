variable "region" {
  default = "us-east-1"
}

variable "floci_endpoint" {
  default = "http://localhost:4566"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "ami_id" {
  description = "Amazon Linux AMI"
  default = "ami-12345678"
}