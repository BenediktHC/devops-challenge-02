variable "environment" {
    description = "Environment (dev/prod)"
    type        = string
}

variable "vpc_cidr" {
    description = "CIDR block for VPC"
    type        = string
}

variable "public_subnet_count" {
    description = "Number of public subnets (dev:1, prod:2)"
    type        = number
}