# Generate random suffix for unique resource naming
resource "random_id" "suffix" {
  byte_length = 4
}

# ========================================
# STRATEGIC FIX: Centralized Tagging
# ========================================
locals {
  common_tags = merge(var.tags, {
    Purpose = "EKS-Cluster-${var.name}"
  })
}

# ========================================
# IAM Roles for EKS
# ========================================

# EKS cluster role
resource "aws_iam_role" "default_cluster" {
  name               = "devops-lia-team-${var.name}-cluster-role-${random_id.suffix.hex}"
  assume_role_policy = data.aws_iam_policy_document.eks_assume.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "eks_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.default_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Node group role
resource "aws_iam_role" "default_node" {
  name               = "devops-lia-team-${var.name}-node-role-${random_id.suffix.hex}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "worker_node" {
  role       = aws_iam_role.default_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni" {
  role       = aws_iam_role.default_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_ro" {
  role       = aws_iam_role.default_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ========================================
# EKS Cluster Resources
# ========================================

resource "aws_security_group" "default" {
  name        = "${var.name}-cluster-sg-${random_id.suffix.hex}"
  description = "EKS cluster security group"
  vpc_id      = var.vpc_id
  tags        = local.common_tags
}

resource "aws_eks_cluster" "default" {
  name     = "${var.name}-${random_id.suffix.hex}"
  role_arn = aws_iam_role.default_cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    security_group_ids      = [aws_security_group.default.id]
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  }

  tags = local.common_tags
}

resource "aws_eks_node_group" "default" {
  for_each        = var.node_groups
  cluster_name    = aws_eks_cluster.default.name
  node_group_name = "${var.name}-${each.key}-${random_id.suffix.hex}"
  node_role_arn   = aws_iam_role.default_node.arn
  subnet_ids      = var.private_subnet_ids
  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  instance_types = each.value.instance_types
  ami_type       = try(each.value.ami_type, "AL2023_x86_64_STANDARD")
  capacity_type  = try(each.value.capacity_type, "ON_DEMAND")

  labels = merge(
    try(each.value.labels, {}),
    {
      "node_group" = each.key
    }
  )

  update_config {
    max_unavailable = try(each.value.max_unavailable, 1)
  }

  tags = merge(
    local.common_tags,
    {
      "Name"      = "${var.name}-${each.key}"
      "NodeGroup" = each.key
    }
  )

  depends_on = [aws_eks_cluster.default]
}

# Dynamically fetch TLS certificate thumbprint from OIDC issuer
data "tls_certificate" "default" {
  url = aws_eks_cluster.default.identity[0].oidc[0].issuer
}

# Create IAM OIDC Provider for IRSA (IAM Roles for Service Accounts)
# This allows Kubernetes service accounts to assume IAM roles, enabling fine-grained
# permissions for pods without using static credentials or node IAM roles.
# The OIDC provider establishes trust between EKS and AWS IAM.
resource "aws_iam_openid_connect_provider" "default" {
  url             = aws_eks_cluster.default.identity[0].oidc[0].issuer              # EKS cluster's OIDC issuer URL
  client_id_list  = ["sts.amazonaws.com"]                                           # Audience for the OIDC token
  thumbprint_list = [data.tls_certificate.default.certificates[0].sha1_fingerprint] # TLS cert fingerprint for secure validation

  tags = local.common_tags
}
