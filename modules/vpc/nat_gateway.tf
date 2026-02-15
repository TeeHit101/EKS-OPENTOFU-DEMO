# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  for_each = toset(local.nat_gateway_azs)

  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-nat-${each.key}"
      AZ   = each.key
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways (one per AZ for high availability)
resource "aws_nat_gateway" "main" {
  for_each = toset(local.nat_gateway_azs)

  allocation_id = aws_eip.nat[each.key].id
  subnet_id = [
    for name, subnet in aws_subnet.public :
    subnet.id if subnet.availability_zone == each.key
  ][0]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-nat-${each.key}"
      AZ   = each.key
    }
  )

  depends_on = [aws_internet_gateway.main]
}
