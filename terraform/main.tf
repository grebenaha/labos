# Define provider
provider "aws" {
  region = "eu-west-1"
  profile = "labos"
}

# Define VPC
resource "aws_vpc" "igor_vpc" {
  cidr_block = "10.10.0.0/16"
  tags = {
    Name = "igor-vpc"
  }
}

# Define internet gateway
resource "aws_internet_gateway" "igor_igw" {
  vpc_id = aws_vpc.igor_vpc.id
  tags = {
    Name = "igor-igw"
  }
}

# Define public subnet
resource "aws_subnet" "igor_public_subnet" {
  vpc_id = aws_vpc.igor_vpc.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = true
  depends_on = [aws_internet_gateway.igor_igw]
  
  tags = {
    Name = "igor-public-subnet"
  }
}

# Define private subnet
resource "aws_subnet" "igor_private_subnet" {
  vpc_id = aws_vpc.igor_vpc.id
  cidr_block = "10.10.2.0/24"
  availability_zone = "eu-west-1b"
  tags = {
    Name = "igor-private-subnet"
  }
}

# Define route table for public subnet
resource "aws_route_table" "igor_public_route_table" {
  vpc_id = aws_vpc.igor_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igor_igw.id
  }

  tags = {
    Name = "igor-public-route-table"
  }
}

# Associate public subnet with public route table
resource "aws_route_table_association" "igor_public_subnet_association" {
  subnet_id = aws_subnet.igor_public_subnet.id
  route_table_id = aws_route_table.igor_public_route_table.id
}

# Define NAT gateway
resource "aws_nat_gateway" "igor_nat_gateway" {
  allocation_id = aws_eip.igor_eip.id
  subnet_id = aws_subnet.igor_public_subnet.id

  tags = {
    Name = "igor-nat-gateway"
  }
}

# Define EIP for NAT gateway
resource "aws_eip" "igor_eip" {
  vpc = true

  tags = {
    Name = "igor-eip"
  }
}

# Define route table for private subnet
resource "aws_route_table" "igor_private_route_table" {
  vpc_id = aws_vpc.igor_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.igor_nat_gateway.id
  }

  tags = {
    Name = "igor-private-route-table"
  }
}

# Associate private subnet with private route table
resource "aws_route_table_association" "igor_private_subnet_association" {
  subnet_id = aws_subnet.igor_private_subnet.id
  route_table_id = aws_route_table.igor_private_route_table.id
}

# Define security group for EC2 instance
resource "aws_security_group" "igor-security-group" {
  name_prefix = "igor-security-group"
  vpc_id = aws_vpc.igor_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "igor_instance" {
  ami           = "ami-022daa15b37b5e55d"
  instance_type = "t2.medium"
  key_name      = "labos_key"
  vpc_security_group_ids = [aws_security_group.igor-security-group.id]
  subnet_id = aws_subnet.igor_public_subnet.id
  depends_on = [tls_private_key.labos_key]
  user_data = <<-EOF
#!/bin/bash

# Clone the repository
git clone https://github.com/grebenaha/lab.git
cd lab
sh run.sh
              EOF

  tags = {
    Name = "igor-instance"
  }
}

