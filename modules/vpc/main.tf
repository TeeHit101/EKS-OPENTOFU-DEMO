resource "aws_vpc" "main" {
  cidr_block           = var.primary_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    local.common_tags,
    {
      Name = var.name
    }
  )
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary" {
  for_each = var.secondary_cidrs

  vpc_id     = aws_vpc.main.id
  cidr_block = each.value.cidr_block
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-igw"
    }
  )
}
