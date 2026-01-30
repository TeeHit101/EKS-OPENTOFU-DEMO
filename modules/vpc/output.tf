output "vpc_id" {
  value       = data.aws_vpc.vpc.id
  description = "The VPC ID"
}

output "vpc_cidr_block" {
  value       = data.aws_vpc.vpc.cidr_block
  description = "The CIDR block of the VPC"
}

output "private_subnet_ids" {
  value       = var.private_subnet_ids
  description = "List of private subnet IDs"
}

output "public_subnet_ids" {
  value       = var.public_subnet_ids
  description = "List of public subnet IDs"
}

output "private_subnets" {
  value       = data.aws_subnet.private[*]
  description = "Private subnet data objects"
}

output "public_subnets" {
  value       = data.aws_subnet.public[*]
  description = "Public subnet data objects"
}
