variable "name" {
  description = "VPC name (e.g., 'tee-test')"
  type        = string
}

variable "primary_cidr" {
  description = "Primary CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones for NAT Gateways (e.g., ['eu-north-1a', 'eu-north-1b'])"
  type        = list(string)
}

variable "secondary_cidrs" {
  description = "Map of secondary CIDR blocks by purpose (e.g., 'eks', 'cloud-only', 'extended-dc1', 'aurora')"
  type = map(object({
    cidr_block = string
    purpose    = string
  }))
  default = {}
}

variable "public_subnets" {
  description = "Map of public subnets by name"
  type = map(object({
    cidr_block        = string
    availability_zone = string
    subnet_type       = optional(string, "general")
    tags              = optional(map(string), {})
  }))
  default = {}
}

variable "private_subnets" {
  description = "Map of private subnets by name"
  type = map(object({
    cidr_block        = string
    availability_zone = string
    nat_gateway_az    = optional(string)
    subnet_type       = optional(string, "general")
    tags              = optional(map(string), {})
  }))
  default = {}
}

variable "nat_gateway_config" {
  description = "NAT Gateway configuration"
  type = object({
    enabled            = bool
    single_nat_gateway = optional(bool, true)
  })
  default = {
    enabled            = true
    single_nat_gateway = true
  }
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "eks_cluster_names" {
  description = "List of EKS cluster names for subnet tagging (kubernetes.io/cluster/<name>=shared)"
  type        = list(string)
  default     = []
}
