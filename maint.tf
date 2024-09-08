provider "aws" {
  region = "ap-south-1"  # Change to your preferred region
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Create a public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1"  # Change to your preferred AZ
  map_public_ip_on_launch = true
}

# Create a private subnet
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1"  # Change to your preferred AZ
}

# Create an internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Create a route table for the public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# Associate the public subnet with the route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create a security group
resource "aws_security_group" "web" {
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  name = "web-sg"
}

# Launch an EC2 instance in the public subnet
resource "aws_instance" "web" {
  ami           = "ami-0522ab6e1ddcc7055"  # Change to your preferred AMI ID
  instance_type = "t2.micro"
  subnet_id     =  aws_subnet.public.id   # subnet-011937719f731cf87
  security_groups = aws_security_group.web.name # sg-0528695a06c7c8e36

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt-get install nginx1 -y
              sudo service nginx start
              EOF

  tags = {
    Name = "web-server"
  }
}
