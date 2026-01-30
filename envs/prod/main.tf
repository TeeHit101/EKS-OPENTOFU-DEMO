locals {
  eks_name = "${var.org_prefix}-dev-eks"
  common_tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Project     = var.org_prefix
  }
}
