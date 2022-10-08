terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
# Configure the AWS Provider
variable "avail_zone" {}

provider "aws" {
  region = "${var.avail_zone}"
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
  instance_tenancy = "default"

  tags = {
    Name = "Application_VPC"
    env = "prod"
  }
}

resource "aws_subnet" "subnet_public" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = var.avail_zone
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
  vpc_id = aws_vpc.my_vpc
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

/* variable "vpc_data" {
  description = "the vpc created in aws"
} */

