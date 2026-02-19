output "ebs_csi_driver_role_arn" {
  description = "IAM Role ARN created for the EBS CSI Driver"
  value       = aws_iam_role.ebs_csi_driver.arn
}

output "vpc_cni_role_arn" {
  description = "IAM Role ARN created for VPC CNI"
  value       = aws_iam_role.vpc_cni.arn
}