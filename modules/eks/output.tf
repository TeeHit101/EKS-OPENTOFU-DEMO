output "cluster_name" { value = aws_eks_cluster.default.name }
output "cluster_endpoint" { value = aws_eks_cluster.default.endpoint }
output "oidc_provider_arn" { value = aws_iam_openid_connect_provider.default.arn }
output "cluster_role_arn" { value = aws_iam_role.default_cluster.arn }
output "node_role_arn" { value = aws_iam_role.default_node.arn }