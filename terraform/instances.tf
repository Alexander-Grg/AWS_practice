resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.subnet_2a.id
  key_name      = aws_key_pair.ansible_key.key_name
 
  vpc_security_group_ids = [aws_security_group.ssh_only.id]

  tags = {
    Name = "AWS_PRACTICE"
  }
}

output "instance_public_ip" {
  value = aws_instance.app_server.public_ip
  description = "Public IP for SSH access"
}

output "instance_public_dns" {
  value = aws_instance.app_server.public_dns
  description = "Public DNS for SSH access"
}