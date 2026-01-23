# Fetch existing VPC
data "aws_vpc" "vpc" {
  id = var.vpc_id
}

# Validate that private subnets exist
data "aws_subnet" "private" {
  count = length(var.private_subnet_ids)
  id    = var.private_subnet_ids[count.index]
}

# Validate that public subnets exist
data "aws_subnet" "public" {
  count = length(var.public_subnet_ids)
  id    = var.public_subnet_ids[count.index]
}

# Tag public subnets for EKS LoadBalancer support
resource "aws_ec2_tag" "public_subnet_elb" {
  count       = var.manage_subnet_tags ? length(var.public_subnet_ids) : 0
  resource_id = var.public_subnet_ids[count.index]
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

# Tag private subnets for EKS internal LoadBalancer support
resource "aws_ec2_tag" "private_subnet_elb" {
  count       = var.manage_subnet_tags ? length(var.private_subnet_ids) : 0
  resource_id = var.private_subnet_ids[count.index]
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

# Tag all subnets with cluster ownership
resource "aws_ec2_tag" "subnet_cluster_shared" {
  count       = var.manage_subnet_tags ? length(concat(var.private_subnet_ids, var.public_subnet_ids)) : 0
  resource_id = concat(var.private_subnet_ids, var.public_subnet_ids)[count.index]
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}