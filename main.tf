provider "aws" {
  region     = "us-east-2"
  access_key = "AKIAVRUVTJL6SLCKDEUF"
  secret_key = "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"
}
# VPC
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

# Subnet
resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr
  availability_zone = "us-east-2a"

  tags = {
    Name = "subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "Route to internet"
  }
}

# Route Table Association
resource "aws_route_table_association" "subnet_assoc" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Security Group
resource "aws_security_group" "car_prediction_sg" {
  vpc_id = aws_vpc.main.id

  // Inbound Rules
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
#car-prediction access from anywhere
ingress  {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Outbound Rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web SG"
  }
}

# Variables
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  default = "10.0.1.0/24"
}

# EC2 Instance
resource "aws_instance" "car_prediction" {
  ami                         = "ami-0ca2e925753ca2fb4"
  instance_type               = "t2.micro"
  count                       = 1
  key_name                    = "key"
  vpc_security_group_ids      = [aws_security_group.car_prediction_sg.id]
  subnet_id                   = aws_subnet.main.id
  associate_public_ip_address = true
  user_data                   = file("userdata.sh")

  tags = {
    Name = "car-prediction-Instance"
  }
}

# Output
output "public_ip" {
  value = aws_instance.car_prediction[*].public_ip
}
