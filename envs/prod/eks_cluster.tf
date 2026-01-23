module "vpc" {
  source = "../../modules/vpc"

  vpc_id             = var.existing_vpc_id
  private_subnet_ids = var.private_subnet_ids
  public_subnet_ids  = var.public_subnet_ids
  cluster_name       = local.eks_name
}

module "eks" {
  source = "../../modules/eks"
  name   = local.eks_name
  region = var.region

  vpc_id             = var.existing_vpc_id
  private_subnet_ids = var.private_subnet_ids
  public_subnet_ids  = var.public_subnet_ids
  tags               = local.common_tags

  # Node groups configuration
  node_groups = {
    # Node 1: Standard on-demand instances
    general = {
      desired_size   = 2
      min_size       = 1
      max_size       = 3
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      #Label for Affinity
      labels = {
        "workload" = "general"
        "team"     = "devops"
      }
    }
    # Node 2: Spot instances 
    spot = {
      desired_size   = 1
      min_size       = 0
      max_size       = 2
      instance_types = ["t3.small"]
      capacity_type  = "SPOT"
      #Label for Affinity
      labels = {
        "workload" = "spot"
        "cost"     = "low"
      }
    }
  }

  enable_cluster_creator_admin_permissions = true
}