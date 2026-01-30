# Terraform Variables for STAGE Environment
# Copy this to terraform.tfvars and fill in your actual values

# AWS Region
region = "eu-north-1"

# Organization prefix
org_prefix = "visma"

# Bootstrap state bucket (where bootstrap outputs are stored)
bootstrap_state_bucket = "devops-lia-team-visma-tf-state-660483628600"

# IAM roles that can assume Terraform roles
trusted_principal_arns = [
  # "arn:aws:iam::ACCOUNT_ID:role/YourRole",
  # "arn:aws:iam::ACCOUNT_ID:user/YourUser"
]

# Existing VPC Configuration
# Replace with your actual VPC and subnet IDs
existing_vpc_id = "vpc-07c49991dc3be07f5"

private_subnet_ids = [
  "subnet-0294b309e91022ff3", # Private subnet AZ1
  "subnet-0a0fd8731721e8e2a", # Private subnet AZ2
]

public_subnet_ids = [
  "subnet-0c1936f97c2f6dbb0", # Public subnet AZ1
  "subnet-0af4bb2118fb33e23", # Public subnet AZ2
]
