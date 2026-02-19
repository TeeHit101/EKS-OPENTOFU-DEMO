variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used for EBS encryption"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "pod_identity_agent_version" {
  description = "Version of the EKS Pod Identity Agent addon"
  type        = string
  default     = "v1.3.10-eksbuild.2"
}

variable "vpc_cni_version" {
  description = "Version of the VPC CNI addon"
  type        = string
  default     = "v1.21.1-eksbuild.1"
}

variable "coredns_version" {
  description = "Version of the CoreDNS addon"
  type        = string
  default     = "v1.12.4-eksbuild.1"
}

variable "kube_proxy_version" {
  description = "Version of the Kube-proxy addon"
  type        = string
  default     = "v1.34.1-eksbuild.2"
}

variable "ebs_csi_driver_version" {
  description = "Version of the EBS CSI Driver addon"
  type        = string
  default     = "v1.54.0-eksbuild.1"
}

variable "metrics_server_version" {
  description = "Version of the Metrics Server addon (EKS Community Addon)"
  type        = string
  default     = "v0.7.2-eksbuild.1"
}

variable "system_node_groups" {
  description = "List of node group names where system pods (CoreDNS, EBS CSI, Metrics Server) should be scheduled"
  type        = list(string)
}