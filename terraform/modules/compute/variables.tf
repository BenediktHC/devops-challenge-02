variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "private_subnet_id" {
  description = "Private subnet ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "create_reverse_proxy" {
  description = "Creating a reverse proxy (true for prod, false for dev)"
  type        = bool
  default     = false
}

variable "ssh_key_name" {
  description = "Name of SSH key pair"
  type        = string
  default     = "ansible-key"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
}