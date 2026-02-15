terraform {
  required_version = "~> 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.28.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

# Get current IAM role for trust policy
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

locals {
  bucket_name        = "${var.bucket_name_prefix}-${data.aws_caller_identity.current.account_id}"
  trusted_principals = length(var.github_repositories) > 0 ? var.github_repositories : [data.aws_iam_session_context.current.issuer_arn]

  # GitHub OIDC Configuration - Only allow the current environment
  github_repositories = ["repo:hrplus/platform-infra:environment:${var.environment}"]

  tags = {
    Owner       = var.org_prefix
    ManagedBy   = "terraform-bootstrap"
    Environment = var.environment
  }
}

# Optional KMS key (can be used for SSE-KMS)
resource "aws_kms_key" "tf_state" {
  count                   = var.create_kms ? 1 : 0
  description             = "KMS key for Terraform state encryption"
  enable_key_rotation     = true
  multi_region            = true
  deletion_window_in_days = 30
  tags = {
    "Purpose" = "30 days to regret deletion of key"
  }
}

resource "aws_kms_alias" "tf_state" {
  count         = var.create_kms ? 1 : 0 # Created only if you want KMS
  name          = "alias/${var.org_prefix}-tf-state"
  target_key_id = aws_kms_key.tf_state[0].key_id
}

resource "aws_s3_bucket" "tf_state" {
  bucket = local.bucket_name
  tags   = local.tags
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.create_kms ? "aws:kms" : "AES256"
      kms_master_key_id = var.create_kms ? aws_kms_key.tf_state[0].arn : null
    }
  }
}

# Mandatory: Block all public access to state bucket (AWS security best practice)
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# (Optional but strongly recommended) - block accidental deletion via bucket-lifecycle/locks in production
# Here we only use versioning + backup procedures via your pipeline.

resource "aws_dynamodb_table" "tf_lock" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = local.tags
}

# GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  tags = merge(
    local.tags,
    {
      Name = "${var.org_prefix}-github-oidc"
    }
  )
}

# IAM Role for GitHub Actions with OIDC trust
data "aws_iam_policy_document" "github_oidc_assume_role" {
  statement {
    sid     = "AllowGitHubOIDC"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.github_repositories
    }
  }
}

resource "aws_iam_role" "plan" {
  name               = "GitHubActionsTerraformPlan"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json
  description        = "GitHub Actions OIDC role for Terraform planning"
  tags               = local.tags
}

resource "aws_iam_role" "apply" {
  name               = "GitHubActionsTerraformApply"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json
  description        = "GitHub Actions OIDC role for Terraform apply"
  tags               = local.tags
}

# Attach AdministratorAccess to Apply role for infrastructure management
resource "aws_iam_role_policy_attachment" "apply_admin" {
  role       = aws_iam_role.apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Attach ReadOnlyAccess to Plan role
resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "state_access" {
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket", "s3:GetBucketVersioning"]
    resources = [aws_s3_bucket.tf_state.arn]
  }

  statement {
    sid = "StateObjectAccess"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["${aws_s3_bucket.tf_state.arn}/*"]
  }

  statement {
    sid = "StateLocking"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      aws_dynamodb_table.tf_lock.arn
    ]
  }
}

resource "aws_iam_policy" "state_access" {
  name   = "${var.org_prefix}-TerraformStateAccess"
  policy = data.aws_iam_policy_document.state_access.json
}

resource "aws_iam_role_policy_attachment" "plan_state" {
  role       = aws_iam_role.plan.name
  policy_arn = aws_iam_policy.state_access.arn
}

resource "aws_iam_role_policy_attachment" "apply_state" {
  role       = aws_iam_role.apply.name
  policy_arn = aws_iam_policy.state_access.arn
}
