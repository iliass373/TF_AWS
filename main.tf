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
  region = var.avail_zone
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet_1" {
    vpc_id = aws_vpc.my_vpc.id
}

data "aws_vpc" "vpc_2" {
  vpc_id = var.vpc_data
}

variable "vpc_data" {
  description = "the vpc created in aws"
}

