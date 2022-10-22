# Configure the AWS Provider ( env variable)
variable "avail_zone" {}
variable "cidr_block_vpc" {
  description = "the cidr block for the vpc"
}
variable "cidr_block_subnet" {
  description = "the cidr block for the subnet"
}
variable "instance_type" {
  description = "put here the instance type"
  default = "t2.micro"
}
variable "path_key_public" {
  description = "put here the path of your ida_rsa.pub"
}
