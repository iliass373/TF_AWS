output "aws_ami" {
  value = data.aws_ami.aws_image_linux.id
}
output "aws_ec2_ipv4" {
  value = aws_instance.instance_app.public_ip
}