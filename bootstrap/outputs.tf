output "state_bucket_name" {
  value = aws_s3_bucket.tf_state.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.tf_lock.name
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_plan_role_arn" {
  description = "ARN of the GitHub Actions Terraform plan role"
  value       = aws_iam_role.plan.arn
}

output "github_apply_role_arn" {
  description = "ARN of the GitHub Actions Terraform apply role"
  value       = aws_iam_role.apply.arn
}
