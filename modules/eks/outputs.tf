output "cluster_security_group_id" {
  description = "ID of the custom EKS cluster security group"
  value       = aws_security_group.default.id
}

output "cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = aws_eks_cluster.default.id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.default.name
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.default.arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.default.endpoint
}

output "cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = aws_eks_cluster.default.version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.default.certificate_authority[0].data
}

output "cluster_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.default_cluster.arn
}

output "cluster_role_name" {
  description = "Name of the EKS cluster IAM role"
  value       = aws_iam_role.default_cluster.name
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  value       = aws_iam_openid_connect_provider.default.arn
}

output "oidc_issuer_url" {
  description = "The URL of the OIDC issuer"
  value       = aws_eks_cluster.default.identity[0].oidc[0].issuer
}

output "oidc_issuer" {
  description = "The OIDC issuer URL without https:// prefix"
  value       = replace(aws_eks_cluster.default.identity[0].oidc[0].issuer, "https://", "")
}

output "node_groups" {
  description = "Map of node group resources"
  value       = aws_eks_node_group.default
}

output "node_role_arn" {
  description = "ARN of the node IAM role"
  value       = aws_iam_role.default_node.arn
}

output "node_role_name" {
  description = "Name of the node IAM role"
  value       = aws_iam_role.default_node.name
}

output "node_group_names" {
  description = "List of node group names"
  value       = [for ng in aws_eks_node_group.default : ng.node_group_name]
}
