# Terraform Variables for DEV Environment
# Copy this to terraform.tfvars and fill in your actual values

# AWS Region
region = "eu-north-1"

# Organization prefix
org_prefix = "devops-tf"

# Bootstrap state bucket (where bootstrap outputs are stored)
bootstrap_state_bucket = "devops-tf-state-123456789012" # Replace with your actual account ID

# IAM roles that can assume Terraform roles
trusted_principal_arns = [
  # "arn:aws:iam::ACCOUNT_ID:role/YourRole",
  # "arn:aws:iam::ACCOUNT_ID:user/YourUser"
]

# Existing VPC Configuration
# Replace with your actual VPC and subnet IDs
existing_vpc_id = "byt ut" # VPC ID

private_subnet_ids = [
  "byt ut", # Private subnet AZ1
  "byt ut", # Private subnet AZ2
]

public_subnet_ids = [
  "byt ut", # Public subnet AZ1
  "byt ut", # Public subnet AZ2
]
