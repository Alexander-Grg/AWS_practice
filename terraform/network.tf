# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = "172.31.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "main-vpc"
    Environment = "production"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_subnet" "subnet_2a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.31.0.0/20"
  availability_zone       = "ap-southeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-2a"
  }
}

resource "aws_subnet" "subnet_2b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.31.32.0/20"
  availability_zone       = "ap-southeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-2b"
  }
}

resource "aws_subnet" "subnet_2c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.31.16.0/20"
  availability_zone       = "ap-southeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-2c"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "main-route-table"
  }
}

resource "aws_route_table_association" "subnet_2a" {
  subnet_id      = aws_subnet.subnet_2a.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "subnet_2b" {
  subnet_id      = aws_subnet.subnet_2b.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "subnet_2c" {
  subnet_id      = aws_subnet.subnet_2c.id
  route_table_id = aws_route_table.main.id
}

resource "aws_db_subnet_group" "webapp_db_subnet_group" {
  name       = "webapp-db-subnet-group"
  subnet_ids = [aws_subnet.subnet_2a.id, aws_subnet.subnet_2b.id, aws_subnet.subnet_2c.id]

  tags = {
    Name        = "webapp-db-subnet-group"
    Environment = "development"
  }
}