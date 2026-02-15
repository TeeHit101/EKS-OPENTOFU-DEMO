variable "name" {
  type = string
}

variable "org_prefix" {
  description = "Organization prefix for resource naming"
  type        = string
}

variable "region" {
  type = string
}

variable "cluster_version" {
  type    = string
  default = "1.35"
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "system_node_groups" {
  description = "Map of system node group sizing configurations. Labels, taints and capacity type are applied automatically."
  type = map(object({
    desired_size   = number
    min_size       = number
    max_size       = number
    instance_types = list(string)
  }))
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "access_entries" {
  description = "Map of access entries to add to the cluster"
  type        = any
  default     = {}
}

variable "karpenter" {
  description = "Karpenter configuration"
  type = object({
    chart_version          = optional(string, "1.8.6")
    additional_helm_values = optional(map(any), {})
  })
  default = {
    chart_version          = "1.8.6"
    additional_helm_values = {}
  }
}

variable "external_secrets" {
  description = "Configuration for the External Secrets Operator"
  default     = {}
}
