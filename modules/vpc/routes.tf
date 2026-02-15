# Public Route Table (shared across all public subnets)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-public"
      Type = "public"
    }
  )
}

# Route to Internet Gateway for public subnets
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Public Subnet Route Table Associations
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Private Route Tables (one per AZ for multi-AZ NAT Gateway support)
resource "aws_route_table" "private" {
  for_each = toset(var.availability_zones)

  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-private-${each.key}"
      Type = "private"
      AZ   = each.key
    }
  )
}

# Route to NAT Gateway for private subnets
resource "aws_route" "private_nat_gateway" {
  for_each = var.nat_gateway_config.enabled ? aws_route_table.private : {}

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  # Use first NAT Gateway when single_nat_gateway is enabled
  nat_gateway_id = var.nat_gateway_config.single_nat_gateway ? values(aws_nat_gateway.main)[0].id : aws_nat_gateway.main[each.key].id
}

# Private Subnet Route Table Associations
resource "aws_route_table_association" "private" {
  for_each = var.private_subnets

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[local.private_subnet_nat_mapping[each.key]].id
}
