# VPC configuration
resource "aws_vpc" "main" {
    cidr_block              = var.vpc_cidr
    enable_dns_hostnames    = true
    enable_dns_support      = true

    tags = {
        Name        = "${var.environment}-vpc"
        Environment = var.environment
    }
}

# Public subnets for web servers
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

# Private subnets for database 
resource "aws_subnet" "private" {
    count               = 2
    vpc_id              = aws_vpc.main.id 
    cidr_block          = cidrsubnet(var.vpc_cidr, 8, count.index + 2)
    availability_zone   = data.aws_availability_zones.available.names[count.index]

    tags = {
        Name        = "${var.environment}-private-subnet-${count.index + 1}"
        Environment = var.environment
    }
}

resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name        = "${var.environment}-igw"
        Environment = var.environment
    }
}

# NAT Gateway for private sn 
resource "aws_nat_gateway" "main" {
    allocation_id = aws_eip.nat.id
    subnet_id     = aws_subnet.public[0].id

    tags = {
        Name        = "${var.environment}-nat"
        Environment = var.environment
    }
}

# Elastic IP for NAT Gateway 
resource "aws_eip" "nat" {
    domain = "vpc"

    tags = {
        Name        = "${var.environment}-nat-eip"
        Environment = var.environment
    }
}

# Route tables 
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.environment}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "${var.environment}-private-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Data source for AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Outputs 
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}