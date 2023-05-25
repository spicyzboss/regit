provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  token      = var.aws_session_token
  region     = var.region
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.branch_prefix} VPC"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "${var.region}a"
  depends_on        = [aws_vpc.main]

  tags = {
    Name = "${var.branch_prefix} Public Subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"
  depends_on        = [aws_vpc.main]

  tags = {
    Name = "${var.branch_prefix} Private Subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id     = aws_vpc.main.id
  depends_on = [aws_vpc.main]

  tags = {
    Name = "${var.branch_prefix} Internet Gateway"
  }
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  depends_on = [aws_internet_gateway.main, aws_vpc.main]

  tags = {
    Name = "${var.branch_prefix} Public Route"
  }
}

resource "aws_route_table_association" "public_route_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_route.id
  depends_on     = [aws_subnet.public, aws_route_table.public_route]
}

resource "aws_security_group" "default" {
  name        = "${var.branch_prefix} Security Group"
  description = "Allows SSH access from anywhere and HTTP access from the internet."

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "vpc" {
  value = aws_vpc.main.arn
}

output "public_subnet" {
  value = aws_subnet.public.arn
}

output "private_subnet" {
  value = aws_subnet.private.arn
}