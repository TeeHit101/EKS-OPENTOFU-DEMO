variable "cluster_name" {
  description = "The name of the cluster to name the key alias"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the KMS key"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "AWS Region (needed for CloudWatch logs principal)"
  type        = string
  default     = "eu-north-1"
}