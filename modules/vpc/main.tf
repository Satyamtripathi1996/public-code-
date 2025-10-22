locals { name = var.project }

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(var.tags, { Name = "${local.name}-vpc" })
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${local.name}-igw" })
}

# Public subnets (2) - multi AZ
resource "aws_subnet" "public" {
  for_each = {
    a = { az = var.azs[0], cidr = cidrsubnet(var.vpc_cidr, 4, 0) }
    b = { az = var.azs[1], cidr = cidrsubnet(var.vpc_cidr, 4, 1) }
  }
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name = "${local.name}-public-${each.key}"
    Tier = "public"
  })
}

# Private subnets (2) - multi AZ
resource "aws_subnet" "private" {
  for_each = {
    a = { az = var.azs[0], cidr = cidrsubnet(var.vpc_cidr, 4, 10) }
    b = { az = var.azs[1], cidr = cidrsubnet(var.vpc_cidr, 4, 11) }
  }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = merge(var.tags, {
    Name = "${local.name}-private-${each.key}"
    Tier = "private"
  })
}

# EIPs for NAT (per AZ for HA)
resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  domain   = "vpc"
  tags     = merge(var.tags, { Name = "${local.name}-nat-eip-${each.key}" })
}

# NAT Gateways (per AZ)
resource "aws_nat_gateway" "nat" {
  for_each      = aws_subnet.public
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id
  tags          = merge(var.tags, { Name = "${local.name}-nat-${each.key}" })
  depends_on    = [aws_internet_gateway.igw]
}

# Public Route Table + routes + associations
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${local.name}-public-rt" })
}

resource "aws_route" "public_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

# Private Route Tables (per AZ) + NAT routes + associations
resource "aws_route_table" "private" {
  for_each = aws_nat_gateway.nat
  vpc_id   = aws_vpc.this.id
  tags     = merge(var.tags, { Name = "${local.name}-private-rt-${each.key}" })
}

resource "aws_route" "private_nat" {
  for_each               = aws_route_table.private
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[each.key].id
}

resource "aws_route_table_association" "private_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = aws_subnet.private[each.key].id
  # map 'a' private subnet to 'a' NAT RT, etc.
  route_table_id = aws_route_table.private[each.key].id
}
