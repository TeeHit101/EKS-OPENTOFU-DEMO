module "eks" {
  source     = "../../modules/eks"
  name       = local.eks_name
  org_prefix = var.org_prefix
  region     = var.region

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  tags               = local.common_tags

  # Node groups configuration
  system_node_groups = var.system_node_groups

  # Access entries from terraform.tfvars (Least Privilege Principle)
  access_entries = var.eks_access_entries
}
