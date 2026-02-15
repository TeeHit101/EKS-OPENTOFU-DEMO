output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "The primary CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks associated with the VPC"
  value = [
    for assoc in aws_vpc_ipv4_cidr_block_association.secondary : assoc.cidr_block
  ]
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "public_subnet_ids_map" {
  description = "Map of public subnet names to IDs (e.g., pub-1a => subnet-xxx)"
  value = {
    for key, subnet in aws_subnet.public : key => subnet.id
  }
}

output "private_subnet_ids_map" {
  description = "Map of private subnet names to IDs (e.g., eks-1a => subnet-xxx)"
  value = {
    for key, subnet in aws_subnet.private : key => subnet.id
  }
}

output "public_subnets" {
  description = "Map of public subnet objects with all attributes"
  value       = aws_subnet.public
}

output "private_subnets" {
  description = "Map of private subnet objects with all attributes"
  value       = aws_subnet.private
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "Map of private route table IDs by AZ"
  value = {
    for az, rt in aws_route_table.private : az => rt.id
  }
}

output "nat_gateway_ids" {
  description = "Map of NAT Gateway IDs by AZ"
  value = {
    for az, nat in aws_nat_gateway.main : az => nat.id
  }
}

output "nat_gateway_public_ips" {
  description = "Map of NAT Gateway public IPs by AZ"
  value = {
    for az, eip in aws_eip.nat : az => eip.public_ip
  }
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = var.availability_zones
}
