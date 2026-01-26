resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.subnet_2a.id
 
  vpc_security_group_ids = [aws_security_group.ssh_only.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "AWS_PRACTICE"
  }
}

output "instance_public_ip" {
  value = aws_instance.app_server.public_ip
  description = "Public IP (Managed via SSM)"
}

output "instance_public_dns" {
  value = aws_instance.app_server.public_dns
  description = "Public DNS for SSH access"
}