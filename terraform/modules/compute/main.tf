data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical 

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "web" {
  name        = "${var.environment}-web-security-group"
  description = "Security group for web servers"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-web-security-group"
    Environment = var.environment
  }
}

resource "aws_security_group" "db" {
  name        = "${var.environment}-db-security-group"
  description = "Security group for PostgreSQL"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-db-security-group"
    Environment = var.environment
  }
}

resource "aws_security_group" "reverse_proxy" {
  count = var.create_reverse_proxy ? 1 : 0

  name        = "${var.environment}-reverse_proxy-security-group"
  description = "Security Group for Nginx reverse proxy"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-reverse-proxy-security-group"
    Environment = var.environment
  }
}

# Web Server/s 
resource "aws_instance" "web" {
  count = var.environment == "dev" ? 1 : 2

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_ids[count.index]

  vpc_security_group_ids = [aws_security_group.web.id]

  tags = {
    Name = "${var.environment}-web-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_instance" "db" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.private_subnet_id

  vpc_security_group_ids = [aws_security_group.db.id]

  tags = {
    Name        = "${var.environment}-db"
    Environment = var.environment
  }
}

resource "aws_instance" "reverse_proxy" {
  count = var.create_reverse_proxy ? 1 : 0

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_ids[0]

  vpc_security_group_ids = [aws_security_group.reverse_proxy[0].id]

  tags = {
    Name        = "${var.environment}-reverse-proxy"
    Environment = var.environment
  }
}