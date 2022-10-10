terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
# Configure the AWS Provider ( env variable)
variable "avail_zone" {}

provider "aws" {
  region = "${var.avail_zone}"
}

variable "cidr_block_vpc" {
  description = "the cidr block for the vpc"
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = var.cidr_block_vpc
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
  instance_tenancy = "default"

  tags = {
    Name = "Application_VPC"
    env = "prod"
  }
}

variable "cidr_block_subnet" {
  description = "the cidr block for the subnet"
}

resource "aws_subnet" "subnet_public" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = var.cidr_block_subnet
  map_public_ip_on_launch = "true"
  availability_zone = "${var.avail_zone}"
  tags = {
    Name = "Application_public_subnet"
  }
}

resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    "Name" = "Application_IGW"
  }
}

resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    //associated subnet can reach everywhere
    cidr_block = "0.0.0.0/0"         
    
    //CRT uses this IGW to reach internet
    gateway_id = aws_internet_gateway.IGW.id 
  }
  tags = {
    "Name" = "Application_RouteTable"
  }
}
# we have to associate the Route table with the subnet
resource "aws_route_table_association" "RT_subnet_Associate" {
  subnet_id = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_security_group" "SG_instance" {
  name = "SG_Application"
  description = "this sg is for the web application port 22 & http/s 80 443"
  vpc_id = aws_vpc.my_vpc.id
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
    }
}

resource "aws_security_group" "SG_alb" {
  name        = "alb_security_group"
  description = "Terraform load balancer security group"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-example-alb-security-group"
  }
}

data "aws_ami" "id-1390339_instanceimage" {
  filter {
    name = "owner"
    values = ["iliass"]
  }
}

resource "aws_instance" "instance_syntx" {
  ami           = data.aws_ami.id-1390339_instanceimage.id
  instance_type = "t2.small"
}

