variable "vpc_id" {
  type        = string
  description = "Existing VPC ID"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs in the existing VPC"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs in the existing VPC"
  default     = []
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name for subnet tagging"
}

variable "manage_subnet_tags" {
  type        = bool
  description = "Whether to manage subnet tags (disable for existing clusters)"
  default     = true
}