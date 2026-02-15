locals {
  eks_name = "${var.org_prefix}-${var.environment}-eks"
  common_tags = {
    Environment = var.environment
    ManagedBy   = "opentofu"
    Project     = var.org_prefix
  }
}
