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
    from_port   = 22  # SSH added for Ansible
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.private_subnet_cidr]
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
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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
  key_name               = aws_key_pair.ansible.key_name

  source_dest_check = false           # Enables NAT 

  tags = {
    Name        = "${var.environment}-web-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_instance" "db" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.private_subnet_id

  vpc_security_group_ids = [aws_security_group.db.id]
  key_name               = aws_key_pair.ansible.key_name

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
  key_name               = aws_key_pair.ansible.key_name

  tags = {
    Name        = "${var.environment}-reverse-proxy"
    Environment = var.environment
  }
}

resource "null_resource" "ansible_provisioner" {
 depends_on = [
   aws_instance.web,
   aws_instance.db,
   aws_instance.reverse_proxy
 ]

 # Trigger for the provisioner whenever IPs change so it can be changed in Ansible 
 triggers = {
   web_ips = join(",", aws_instance.web[*].public_ip)
   db_ip = aws_instance.db.private_ip
   reverse_proxy_ip = var.create_reverse_proxy ? aws_instance.reverse_proxy[0].public_ip : ""
 }

 provisioner "local-exec" {
   command = <<EOT
#!/bin/bash
ANSIBLE_PATH=/home/benediktsteinbacher/Coding/challenge02/ansible
cd $ANSIBLE_PATH

cat > inventory/${var.environment} <<EOF
[webservers]
${join("\n", [for ip in aws_instance.web[*].public_ip : "${ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa ansible_ssh_extra_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'"])}

[databases]
${aws_instance.db.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q ubuntu@${aws_instance.web[0].public_ip}" -o ForwardAgent=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

[reverse_proxy]
${var.create_reverse_proxy ? "${aws_instance.reverse_proxy[0].public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa ansible_ssh_extra_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'" : ""}
EOF

echo "Waiting for instances to be ready..."
sleep 120

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory/${var.environment} ${var.environment}.yml --vault-password-file .vault_pass.txt -vv
EOT
 }
}

resource "aws_key_pair" "ansible" {
 key_name = "${var.environment}-ansible-key"
 public_key = file("~/.ssh/id_rsa.pub")
}