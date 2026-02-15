variable "region" {
  type    = string
  default = "eu-north-1"
}

variable "org_prefix" {
  type    = string
  default = "tee-devops"
}

variable "eks_access_entries" {
  type        = any
  description = "Map of IAM principals and their EKS access policies (Least Privilege)"
  default     = {}
}

variable "environment" {
  type    = string
  default = "test"
}

variable "system_node_groups" {
  description = "Map of system node group sizing configurations"
  type        = any
}

variable "karpenter" {
  description = "Karpenter configuration passed to the karpenter module"
  type        = any
  default     = {}
}
