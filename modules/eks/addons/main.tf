resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# IAM Role for VPC CNI to use Pod Identity
data "aws_iam_policy_document" "vpc_cni_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vpc_cni" {
  name               = "${var.cluster_name}-vpc-cni-role-${random_string.suffix.result}"
  assume_role_policy = data.aws_iam_policy_document.vpc_cni_trust.json
  tags = merge(var.tags, {
    "Purpose" = "Grant the VPC CNI addon permissions to work with the cluster networking"
  })
}

resource "aws_iam_role_policy_attachment" "vpc_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni.name
}

# IAM Policy for EBS CSI Driver to use custom KMS key
resource "aws_iam_policy" "ebs_encryption" {
  name        = "${var.cluster_name}-ebs-encryption-policy-${random_string.suffix.result}"
  description = "Allows EBS CSI Driver to use the custom KMS key"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowKMSGrants"
        Effect   = "Allow"
        Action   = ["kms:CreateGrant", "kms:ListGrants", "kms:RevokeGrant"]
        Resource = [var.kms_key_arn]
        Condition = {
          Bool = { "kms:GrantIsForAWSResource" = "true" }
        }
      },
      {
        Sid    = "AllowKMSEncryptionDecryption"
        Effect = "Allow"
        Action = [
          "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*",
          "kms:GenerateDataKey*", "kms:DescribeKey"
        ]
        Resource = [var.kms_key_arn]
      }
    ]
  })
}

data "aws_iam_policy_document" "ebs_csi_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${var.cluster_name}-ebs-csi-role-${random_string.suffix.result}"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_trust.json
  tags = merge(var.tags, {
    "Purpose" = "Grant EBS CSI driver access to work with disks"
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_aws_managed" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

resource "aws_iam_role_policy_attachment" "ebs_csi_kms_custom" {
  policy_arn = aws_iam_policy.ebs_encryption.arn
  role       = aws_iam_role.ebs_csi_driver.name
}

# Addon Installationer
# Pod Identity Agent Addon
resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name  = var.cluster_name
  addon_name    = "eks-pod-identity-agent"
  addon_version = var.pod_identity_agent_version
}

# VPC CNI Addon
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = var.cluster_name
  addon_name                  = "vpc-cni"
  addon_version               = var.vpc_cni_version
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_addon.pod_identity_agent]

  configuration_values = jsonencode({
    enableWindowsIpam = "true"
  })
}

resource "aws_eks_pod_identity_association" "vpc_cni" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "aws-node"
  role_arn        = aws_iam_role.vpc_cni.arn
}

# CoreDNS Addon
resource "aws_eks_addon" "coredns" {
  cluster_name                = var.cluster_name
  addon_name                  = "coredns"
  addon_version               = var.coredns_version
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_addon.vpc_cni]

  configuration_values = jsonencode({
    affinity = {
      nodeAffinity = {
        requiredDuringSchedulingIgnoredDuringExecution = {
          nodeSelectorTerms = [{
            matchExpressions = [{
              key      = "node_group"
              operator = "In"
              values   = var.system_node_groups
            }]
          }]
        }
      }
    }
  })
}

# Kube-Proxy Addon
resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = var.cluster_name
  addon_name                  = "kube-proxy"
  addon_version               = var.kube_proxy_version
  resolve_conflicts_on_update = "OVERWRITE"
}

# EBS CSI Driver Addon
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = var.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = var.ebs_csi_driver_version
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_addon.pod_identity_agent]

  configuration_values = jsonencode({
    controller = {
      affinity = {
        nodeAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = {
            nodeSelectorTerms = [{
              matchExpressions = [{
                key      = "node_group"
                operator = "In"
                values   = var.system_node_groups
              }]
            }]
          }
        }
      }
    }
  })
}

resource "aws_eks_pod_identity_association" "ebs_csi" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"
  role_arn        = aws_iam_role.ebs_csi_driver.arn
}