provider "aws" {
  region = "ap-southeast-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

data "dotenv" "main" {
  filename = "../.env"
}

data "http" "current_ip" {
  url = "https://ifconfig.me/ip"
}

data "aws_caller_identity" "current" {}