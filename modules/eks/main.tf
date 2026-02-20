resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  common_tags = merge(var.tags, {
    Purpose = "EKS-Cluster-${var.name}"
  })

  system_node_group_names = keys(var.system_node_groups)

  # Expand sizing-only input into full node group configs with standard
  # system-node labels, taints and ON_DEMAND capacity.
  node_groups = {
    for name, config in var.system_node_groups : name => {
      desired_size    = config.desired_size
      min_size        = config.min_size
      max_size        = config.max_size
      instance_types  = config.instance_types
      capacity_type   = "ON_DEMAND"
      ami_type        = "AL2023_x86_64_STANDARD"
      max_unavailable = 1
      labels = {
        "workload" = "system"
        "team"     = "platform"
      }
      taints = [
        {
          key    = "CriticalAddonsOnly"
          effect = "NoSchedule"
        }
      ]
    }
  }
}


# EKS Cluster Role (Control Plane)
resource "aws_iam_role" "default_cluster" {
  name               = "${var.org_prefix}-${var.name}-cluster-role-${random_id.suffix.hex}"
  assume_role_policy = data.aws_iam_policy_document.eks_assume.json
  tags               = local.common_tags
}

# Trust Policy: Allow EKS Service to assume this role
data "aws_iam_policy_document" "eks_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

# Attach standard EKS Cluster Policy
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.default_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Node Group Role
resource "aws_iam_role" "default_node" {
  name               = "${var.org_prefix}-${var.name}-node-role-${random_id.suffix.hex}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = local.common_tags
}

# Trust Policy: Allow EC2 Service to assume this role
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Attach necessary worker node policies
resource "aws_iam_role_policy_attachment" "worker_node" {
  role       = aws_iam_role.default_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.default_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.default_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_security_group" "default" {
  name        = "${var.name}-cluster-sg-${random_id.suffix.hex}"
  description = "EKS cluster security group"
  vpc_id      = var.vpc_id
  tags        = local.common_tags
}

# Allow all egress traffic (required for nodes to communicate)
resource "aws_vpc_security_group_egress_rule" "default_egress" {
  security_group_id = aws_security_group.default.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound traffic"
}

# Allow nodes to communicate with each other
resource "aws_vpc_security_group_ingress_rule" "node_to_node" {
  security_group_id            = aws_security_group.default.id
  referenced_security_group_id = aws_security_group.default.id
  ip_protocol                  = "-1"
  description                  = "Allow nodes to communicate with each other"
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
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      access_config[0].bootstrap_cluster_creator_admin_permissions
    ]
  }
}

resource "aws_eks_node_group" "default" {
  for_each        = local.node_groups
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
  ami_type       = each.value.ami_type
  capacity_type  = each.value.capacity_type

  labels = merge(each.value.labels, {
    "node_group" = each.key
  })

  update_config {
    max_unavailable = each.value.max_unavailable
  }

  tags = merge(
    local.common_tags,
    {
      "Name"      = "${var.name}-${each.key}"
      "NodeGroup" = each.key
    }
  )

  depends_on = [
    aws_eks_cluster.default,
    aws_iam_role_policy_attachment.worker_node,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_read,
  ]
}

#OIDC Provider (Identity)
data "tls_certificate" "default" {
  url = aws_eks_cluster.default.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "default" {
  url             = aws_eks_cluster.default.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.default.certificates[0].sha1_fingerprint]

  tags = local.common_tags
}

# EKS Access Entries
resource "aws_eks_access_entry" "default" {
  for_each = var.access_entries

  cluster_name  = aws_eks_cluster.default.name
  principal_arn = each.value.principal_arn
  type          = try(each.value.type, "STANDARD")
  user_name     = try(each.value.user_name, null)

  depends_on = [aws_eks_cluster.default]
}

resource "aws_eks_access_policy_association" "default" {
  for_each = merge([
    for entry_key, entry_value in var.access_entries : {
      for idx, policy in lookup(entry_value, "policy_associations", []) :
      "${entry_key}-${idx}" => {
        principal_arn = entry_value.principal_arn
        policy_arn    = policy.policy_arn
        access_scope  = lookup(policy, "access_scope", { type = "cluster", namespaces = [] })
      }
    }
  ]...)

  cluster_name  = aws_eks_cluster.default.name
  principal_arn = each.value.principal_arn
  policy_arn    = each.value.policy_arn

  access_scope {
    type       = try(each.value.access_scope.type, "cluster")
    namespaces = try(each.value.access_scope.namespaces, [])
  }

  depends_on = [aws_eks_access_entry.default]
}

# Tag subnets with the actual cluster name (including random suffix) after it is known.
# This cannot be done in the VPC module since the suffix is not known at plan time.
resource "aws_ec2_tag" "private_subnet_cluster" {
  for_each    = { for idx, id in var.private_subnet_ids : tostring(idx) => id }
  resource_id = each.value
  key         = "kubernetes.io/cluster/${aws_eks_cluster.default.name}"
  value       = "shared"
}

resource "aws_ec2_tag" "public_subnet_cluster" {
  for_each    = { for idx, id in var.public_subnet_ids : tostring(idx) => id }
  resource_id = each.value
  key         = "kubernetes.io/cluster/${aws_eks_cluster.default.name}"
  value       = "shared"
}

module "kms" {
  source = "./kms"

  cluster_name = "${var.org_prefix}-${var.name}"
  region       = var.region
  tags         = local.common_tags
}

module "eso" {
  source = "./eso"

  cluster_name  = aws_eks_cluster.default.name
  oidc_provider = aws_iam_openid_connect_provider.default
  region        = var.region
  tags          = local.common_tags

  depends_on = [
    aws_eks_cluster.default,
    aws_eks_node_group.default,
  ]
}

module "addons" {
  source = "./addons"

  cluster_name       = aws_eks_cluster.default.name
  system_node_groups = local.system_node_group_names
  kms_key_arn        = module.kms.key_arn
  tags               = local.common_tags

  depends_on = [
    aws_eks_node_group.default,
    aws_eks_cluster.default,
    module.kms,
  ]
}