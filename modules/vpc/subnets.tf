# Public Subnets
resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    each.value.tags,
    lookup(local.eks_public_subnet_tags, each.key, {}),
    {
      Name = each.key
      Type = "public"
      AZ   = each.value.availability_zone
    }
  )

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.secondary
  ]
}

# Private Subnets
resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false

  tags = merge(
    local.common_tags,
    each.value.tags,
    lookup(local.eks_private_subnet_tags, each.key, {}),
    {
      Name = each.key
      Type = "private"
      AZ   = each.value.availability_zone
    }
  )

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.secondary
  ]
}
