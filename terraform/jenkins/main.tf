provider "aws" {
    region = "eu-central-1"
}

resource "aws_vpc" "jenkins" {
  cidr_block            = "172.16.0.0/16"
  enable_dns_hostnames  = true
  enable_dns_support    = true

  tags = {
    Name = "jenkins-vpc"
  }
}

resource "aws_subnet" "jenkins" {
  vpc_id                    = aws_vpc.jenkins.id
  cidr_block                = "172.16.1.0/24"
  map_public_ip_on_launch   = true

  tags = {
    Name = "jenkins-subnet"
  }
}

resource "aws_internet_gateway" "jenkins" {
  vpc_id = aws_vpc.jenkins.id

  tags = {
    Name = "jenkins-internet-gateway"
  }
}

resource "aws_route_table" "jenkins" {
  vpc_id = aws_vpc.jenkins.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins.id
  }

  tags = {
    Name = "jenkins-route-table"
  }
}

resource "aws_route_table_association" "jenkins" {
  subnet_id      = aws_subnet.jenkins.id
  route_table_id = aws_route_table.jenkins.id
}

resource "aws_security_group" "jenkins" {
  name          = "jenkins-security-group"
  description   = "Security Group for Jenkins server"
  vpc_id        = aws_vpc.jenkins.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-security-group"
  }
}

resource "aws_instance" "jenkins" {
  ami           = "ami-0c0d3776ef525d5dd"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.jenkins.id

  vpc_security_group_ids    = [aws_security_group.jenkins.id]
  key_name                  = "jenkins-key"                     # Placeholder 

  root_block_device {
    volume_size = 8
  }

  lifecycle {
    #prevent_destroy = true
  }

  tags = {
    Name = "jenkins-server"
  }
}

resource "aws_eip" "jenkins" {
  instance  = aws_instance.jenkins.id
  vpc       = true

  tags = {
    Name = "jenkins-eip"
  }
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "jenkins_eip" {
  value = aws_eip.jenkins.public_ip
}