module "vpc" {
  source = "../../modules/vpc"

  # Required variables
  name               = "${var.org_prefix}-${var.environment}"
  primary_cidr       = "10.10.0.0/16"
  availability_zones = ["eu-north-1a", "eu-north-1b"]

  # Public subnets for load balancers and NAT Gateways
  public_subnets = {
    "pub-1a" = {
      cidr_block        = "10.10.1.0/24"
      availability_zone = "eu-north-1a"
      subnet_type       = "eks"
    }
    "pub-1b" = {
      cidr_block        = "10.10.2.0/24"
      availability_zone = "eu-north-1b"
      subnet_type       = "eks"
    }
  }

  # Private subnets for EKS nodes
  private_subnets = {
    "eks-1a" = {
      cidr_block        = "10.10.11.0/24"
      availability_zone = "eu-north-1a"
      subnet_type       = "eks"
    }
    "eks-1b" = {
      cidr_block        = "10.10.12.0/24"
      availability_zone = "eu-north-1b"
      subnet_type       = "eks"
    }
  }

  # Nat Gateway configuration
  nat_gateway_config = {
    enabled            = true
    single_nat_gateway = true # standard single NAT Gateway setup for test environment
  }

  tags = local.common_tags
}
