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
    cidr_blocks = [] # Enter the ip address of your team that want to access the instance
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

data "aws_ami" "aws_image_linux" {
  most_recent = true
  owners = [ "amazon" ]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }
  filter {
    name = "virtualization-type"
    values = [ "hvm" ]
  }
}

variable "instance_type" {
  description = "put here the instance type"
  default = "t2.micro"
}

variable "path_key_public" {
  description = "put here the path of your ida_rsa.pub"
}

resource "aws_key_pair" "app_key_pair" {
  key_name = "application_key_ssh"
  public_key = file(var.path_key_public)
}

resource "aws_instance" "instance_app" {
  ami           = data.aws_ami.aws_image_linux.id
  instance_type = var.instance_type
  
  subnet_id = aws_subnet.subnet_public.id
  vpc_security_group_ids = [aws_security_group.SG_instance.id]
  availability_zone = var.avail_zone
  associate_public_ip_address = true 
  key_name = aws_key_pair.app_key_pair.key_name
  
  tags = {
    "Name" = "myapp_prod_instance" 
  }
}

