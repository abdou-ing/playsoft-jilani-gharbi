resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "floci-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "floci-igw"
  }
}

resource "aws_subnet" "public1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "subnet1" {
  subnet_id = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "subnet2" {
  subnet_id = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web" {
  name = "web-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "nginx" {
  name = "nginx-template"
  image_id = var.ami_id
  instance_type = var.instance_type
  user_data = filebase64("userdata.sh")
  vpc_security_group_ids = [
    aws_security_group.web.id
  ]
}

resource "aws_autoscaling_group" "web" {
  name = "nginx-asg"
  min_size = 1
  max_size = 3
  desired_capacity = 2
  vpc_zone_identifier = [
    aws_subnet.public1.id,
    aws_subnet.public2.id
  ]
  launch_template {
    id = aws_launch_template.nginx.id
    version = "$Latest"
  }
}

resource "aws_lb" "web" {
  name = "nginx-alb"
  load_balancer_type = "application"
  internal = false
  subnets = [
    aws_subnet.public1.id,
    aws_subnet.public2.id
  ]
  security_groups = [
    aws_security_group.web.id
  ]
}
resource "aws_lb_target_group" "web" {
  name = "nginx-target"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_s3_bucket" "backup" {
  bucket = "floci-demo-backup"
  tags = {
    Name = "backup"
  }
}