# Security Group 1: launch-wizard-1
resource "aws_security_group" "launch_wizard_1" {
  name        = "launch-wizard-1"
  description = "launch-wizard-1 created 2025-08-04T06:06:16.489Z"
  vpc_id      = aws_vpc.main.id

  # Inbound Rules
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.dotenv.main.env["ALLOWED_IP"]]
  }

  # Outbound Rules
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "launch-wizard-1"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Security Group 2: default
resource "aws_security_group" "default_sg" {
  name        = "default"
  description = "default VPC security group"
  vpc_id      = aws_vpc.main.id

  # Inbound Rules
  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [data.dotenv.main.env["ALLOWED_IP"]]
  }

  ingress {
    description = "PostgreSQL access for Codespaces"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.dotenv.main.env["CODESPACE_IP"]]
  }

  ingress {
    description     = "PostgreSQL access for Fargate backend service"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.post_srv_sg.id]
  }

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.dotenv.main.env["ALLOWED_IP"]]
  }

  # ingress {
  #   description = "ICMPv6 access"
  #   from_port   = -1
  #   to_port     = -1
  #   protocol    = "icmpv6"
  #   cidr_blocks = [var.icmpv6_ip]
  # }

  # Outbound Rules
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "default"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Security Group 3: post-srv-sg
resource "aws_security_group" "post_srv_sg" {
  name        = "post-srv-sg"
  description = "Security group for Webapp services on ECS"
  vpc_id      = aws_vpc.main.id

  # Inbound Rules
  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [data.dotenv.main.env["ALLOWED_IP"]]
  }

  # Outbound Rules
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "post-srv-sg"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Outputs for reference
output "launch_wizard_1_sg_id" {
  description = "ID of the launch-wizard-1 security group"
  value       = aws_security_group.launch_wizard_1.id
}

output "default_sg_id" {
  description = "ID of the default security group"
  value       = aws_security_group.default_sg.id
}

output "post_srv_sg_id" {
  description = "ID of the post-srv-sg security group"
  value       = aws_security_group.post_srv_sg.id
}
