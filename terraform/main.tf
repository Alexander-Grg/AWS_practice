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
  count    = var.is_codespaces ? 0 : 1  # Only load .env file locally, not in Codespaces
  filename = "../.env"
}