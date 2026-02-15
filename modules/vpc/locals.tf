locals {
  # NAT Gateway configuration
  nat_gateway_azs = var.nat_gateway_config.enabled ? (
    var.nat_gateway_config.single_nat_gateway ? [var.availability_zones[0]] : var.availability_zones
  ) : []

  # Group private subnets by AZ for route table associations
  private_subnets_by_az = {
    for az in var.availability_zones : az => {
      for name, subnet in var.private_subnets : name => subnet
      if subnet.availability_zone == az
    }
  }

  # Map private subnets to their NAT Gateway AZ
  private_subnet_nat_mapping = {
    for name, subnet in var.private_subnets : name => (
      subnet.nat_gateway_az != null ? subnet.nat_gateway_az : (
        var.nat_gateway_config.single_nat_gateway ? var.availability_zones[0] : subnet.availability_zone
      )
    )
  }

  # EKS subnet tags (applied to subnets at creation)
  eks_public_subnet_tags = {
    for name, subnet in var.public_subnets : name => merge(
      {
        "kubernetes.io/role/elb" = "1"
      },
      {
        for cluster_name in var.eks_cluster_names :
        "kubernetes.io/cluster/${cluster_name}" => "shared"
      }
    ) if subnet.subnet_type == "eks"
  }

  eks_private_subnet_tags = {
    for name, subnet in var.private_subnets : name => merge(
      {
        "kubernetes.io/role/internal-elb" = "1"
        "karpenter.sh/discovery"          = var.name
      },
      {
        for cluster_name in var.eks_cluster_names :
        "kubernetes.io/cluster/${cluster_name}" => "shared"
      }
    ) if subnet.subnet_type == "eks"
  }

  common_tags = merge(
    var.tags,
    {
      ManagedBy = "OpenTofu"
      Module    = "vpc"
    }
  )
}
