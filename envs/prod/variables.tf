variable "region" {
  type    = string
  default = "eu-north-1"
}

variable "org_prefix" {
  type    = string
  default = "visma"
}

variable "bootstrap_state_bucket" {
  type        = string
  description = "S3 bucket where bootstrap state is stored"
}

# Specify the entities allowed to assume Terraform roles (e.g. SSO or pipeline)
variable "trusted_principal_arns" {
  type        = list(string)
  default     = []
  description = "List of AWS ARNs allowed to assume Terraform roles"
}


variable "existing_vpc_id" {
  type        = string
  description = "Existing VPC ID (EKS will be created in this VPC)"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs in existing VPC (EKS nodes run here)"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs (used by ALB / public endpoints if desired)"
  default     = []
}
