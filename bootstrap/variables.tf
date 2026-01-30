variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "bucket_name_prefix" {
  description = "Prefix for state bucket. Combined with account-id automatically."
  type        = string
  default     = "devops-team-tf-state"
}

variable "create_kms" {
  description = "If true, a KMS key is created for SSE-KMS. Otherwise SSE-S3 (AES256)."
  type        = bool
  default     = false
}

variable "dynamodb_table_name" {
  description = "Name of DynamoDB table for state locking"
  type        = string
  default     = "terraform-devops-team-lock"
}

variable "org_prefix" {
  description = "Prefix for tags/names (e.g. visma)"
  type        = string
  default     = "devops-team"
}

variable "environment" {
  description = "Environment for tags/names (e.g. dev, prod)"
  type        = string
  default     = "dev"
}

variable "github_repositories" {
  type        = list(string)
  description = "List of GitHub repositories allowed to assume roles via OIDC. Format: 'repo:org/repo:*' or 'repo:org/repo:ref:refs/heads/main'"
  default     = []
}
