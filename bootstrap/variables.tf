variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "bucket_name_prefix" {
  description = "Prefix for state bucket. Combined with account-id automatically."
  type        = string
  default     = "devops-tf-state"
}

variable "create_kms" {
  description = "If true, a KMS key is created for SSE-KMS. Otherwise SSE-S3 (AES256)."
  type        = bool
  default     = false
}

variable "dynamodb_table_name" {
  description = "Name of DynamoDB table for state locking"
  type        = string
  default     = "terraform-devops-tf-lock"
}

variable "org_prefix" {
  description = "Prefix for tags/names (e.g. devops, mycompany)"
  type        = string
  default     = "devops-tf"
}

variable "environment" {
  description = "Environment for tags/names (e.g. dev, prod)"
  type        = string
  default     = "dev"
}

variable "trusted_principal_arns" {
  type        = list(string)
  description = "Entities that can assume Terraform roles (e.g. SSO, GitHub OIDC, etc.). Defaults to current IAM role if empty."
  default     = []
}
