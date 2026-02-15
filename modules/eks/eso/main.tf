resource "random_id" "suffix" {
  byte_length = 4
}

# IAM Policy
resource "aws_iam_policy" "eso_policy" {
  name        = "${var.cluster_name}-eso-policy-${random_id.suffix.hex}"
  description = "Policy for External Secrets Operator to read Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Resource = ["*"]
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = ["*"]
      }
    ]
  })
}

# IAM Role
data "aws_iam_policy_document" "trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eso_role" {
  name               = "${var.cluster_name}-eso-role-${random_id.suffix.hex}"
  assume_role_policy = data.aws_iam_policy_document.trust_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.eso_role.name
  policy_arn = aws_iam_policy.eso_policy.arn
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.versions
  namespace        = var.namespace
  create_namespace = true

  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = var.service_account_name
  }

  depends_on = [aws_iam_role_policy_attachment.attach]
}

# Pod Identity Association for ESO
resource "aws_eks_pod_identity_association" "eso" {
  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = var.service_account_name
  role_arn        = aws_iam_role.eso_role.arn
}

resource "kubectl_manifest" "cluster_secret_store" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "aws-secrets-manager"
    }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = var.region
        }
      }
    }
  })

  force_conflicts   = true
  server_side_apply = true

  depends_on = [
    helm_release.external_secrets,
    aws_eks_pod_identity_association.eso
  ]
}
