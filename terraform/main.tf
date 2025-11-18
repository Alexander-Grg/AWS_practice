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

# Main .env file
data "dotenv" "main" {
  filename = ".env"
}

# Backend .env file
data "dotenv" "backend" {
  filename = "./backend-flask/.env.backend"
}

# Frontend .env file  
data "dotenv" "frontend" {
  filename = "./frontend-react-js/.env.frontend"
}