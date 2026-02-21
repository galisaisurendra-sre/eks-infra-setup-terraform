# =============================================================================
# VPC
# =============================================================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "eks-vpc-${var.env}"
  })
}

# =============================================================================
# PUBLIC SUBNETS  (one per AZ)
# Load Balancers will be placed here.
# =============================================================================
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                                        = "eks-public-${var.env}-${count.index + 1}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

# =============================================================================
# PRIVATE SUBNETS  (one per AZ)
# EKS worker nodes will be placed here.
# =============================================================================
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name                                        = "eks-private-${var.env}-${count.index + 1}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

# =============================================================================
# INTERNET GATEWAY
# Allows public subnets to reach the internet.
# =============================================================================
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "eks-igw-${var.env}"
  })
}

# =============================================================================
# ELASTIC IPs for NAT Gateways  (one per AZ)
# =============================================================================
resource "aws_eip" "nat" {
  count  = length(var.public_subnet_cidrs)
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "eks-nat-eip-${var.env}-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# =============================================================================
# NAT GATEWAYS  (one per AZ for high availability)
# Each private subnet routes outbound traffic through its AZ-local NAT GW.
# =============================================================================
resource "aws_nat_gateway" "main" {
  count = length(var.public_subnet_cidrs)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "eks-nat-gw-${var.env}-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# =============================================================================
# ROUTE TABLE — PUBLIC
# Single route table shared by all public subnets → routes to IGW.
# =============================================================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "eks-public-rt-${var.env}"
  })
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# =============================================================================
# ROUTE TABLES — PRIVATE  (one per AZ)
# Each private subnet routes outbound traffic to its AZ-local NAT Gateway.
# Using separate route tables per AZ ensures AZ-level fault isolation.
# =============================================================================
resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(var.tags, {
    Name = "eks-private-rt-${var.env}-${count.index + 1}"
  })
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# =============================================================================
# SECURITY GROUP — VPC Interface Endpoints
# Allows HTTPS (443) traffic from within the VPC to reach interface endpoints.
# =============================================================================
resource "aws_security_group" "vpc_endpoints" {
  name        = "eks-vpc-endpoints-sg-${var.env}"
  description = "Allow HTTPS from VPC CIDR to interface VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "eks-vpc-endpoints-sg-${var.env}"
  })
}

# =============================================================================
# VPC ENDPOINT — S3 (Gateway type)
# Gateway endpoints are free and attach to route tables directly.
# Keeps S3 traffic (ECR layer pulls) inside AWS network.
# =============================================================================
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat([aws_route_table.public.id], aws_route_table.private[*].id)

  tags = merge(var.tags, {
    Name = "eks-s3-endpoint-${var.env}"
  })
}

# =============================================================================
# VPC ENDPOINTS — Interface type
# Keeps ECR, STS, and CloudWatch Logs traffic inside the AWS network.
# Required for private EKS nodes to pull images and authenticate without
# traversing the public internet.
# =============================================================================
locals {
  interface_endpoints = {
    ecr_api = "com.amazonaws.us-east-1.ecr.api"
    ecr_dkr = "com.amazonaws.us-east-1.ecr.dkr"
    sts     = "com.amazonaws.us-east-1.sts"
    logs    = "com.amazonaws.us-east-1.logs"
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = aws_vpc.main.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "eks-${each.key}-endpoint-${var.env}"
  })
}
