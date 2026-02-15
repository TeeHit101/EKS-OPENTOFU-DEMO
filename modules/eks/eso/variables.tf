variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "region" {
  description = "The AWS region where the EKS cluster is deployed."
  type        = string
}

variable "oidc_provider" {
  description = "The OIDC provider object associated with the EKS cluster."
  type = object({
    arn = string
  })
}

variable "service_account_name" {
  description = "The name of the external secrets operator service account."
  type        = string
  default     = "external-secret-sa"
}

variable "namespace" {
  description = "The Kubernetes namespace where the external secrets operator will be deployed."
  type        = string
  default     = "external-secrets"
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key used to encrypt secrets in AWS Secrets Manager."
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "versions" {
  description = "Version of the External Secrets Operator Helm chart"
  type        = string
  default     = "2.0.0"
}
