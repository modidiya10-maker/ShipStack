terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.5"

  backend "s3" {
    bucket       = "shipstack-terraform-state"
    key          = "shipstack/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "ap-south-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}

resource "aws_vpc" "shipstack" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "shipstack-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.shipstack.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "shipstack-public-subnet"
  }
}

resource "aws_internet_gateway" "shipstack" {
  vpc_id = aws_vpc.shipstack.id

  tags = {
    Name = "shipstack-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.shipstack.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.shipstack.id
  }

  tags = {
    Name = "shipstack-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web" {
  name        = "shipstack-web"
  description = "Allow HTTP and SSH for ShipStack"
  vpc_id      = aws_vpc.shipstack.id

  ingress {
    description = "HTTP"
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

  tags = {
    Name = "shipstack-web-sg"
  }
}

resource "aws_instance" "shipstack" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y python3-pip python3-venv git

              cd /opt
              git clone https://github.com/modidiya10-maker/ShipStack.git

              cd ShipStack
              python3 -m venv venv
              ./venv/bin/pip install -r app/requirements.txt

              ./venv/bin/gunicorn \
                --chdir app \
                --bind 0.0.0.0:80 \
                app:app
              EOF

  tags = {
    Name = "shipstack-server"
  }
}