variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "bucket_name_prefix" {
  description = "Prefix for state bucket. Combined with account-id automatically."
  type        = string
  default     = "tf-state"
}

variable "create_kms" {
  description = "If true, a KMS key is created for SSE-KMS. Otherwise SSE-S3 (AES256)."
  type        = bool
  default     = false
}

variable "dynamodb_table_name" {
  description = "Name of DynamoDB table for state locking"
  type        = string
  default     = "opentofu-lock"
}

variable "org_prefix" {
  description = "Prefix for tags/names"
  type        = string
  default     = "examen"
}

variable "environment" {
  description = "Environment for tags/names (e.g. dev, prod)"
  type        = string
  default     = "test"
}

variable "github_repositories" {
  type        = list(string)
  description = "List of GitHub repositories allowed to assume roles via OIDC. Format: 'repo:org/repo:*' or 'repo:org/repo:ref:refs/heads/main'"
  default     = []
}
