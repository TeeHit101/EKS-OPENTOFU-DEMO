provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

# Get current IAM role for trust policy
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

locals {
  bucket_name = "${var.bucket_name_prefix}-${data.aws_caller_identity.current.account_id}"
  # Use current role ARN if trusted_principal_arns is empty
  trusted_principals = length(var.trusted_principal_arns) > 0 ? var.trusted_principal_arns : [data.aws_iam_session_context.current.issuer_arn]
  tags = {
    Owner       = var.org_prefix
    ManagedBy   = "terraform-bootstrap"
    Environment = "dev" //  "test", "stage", "prod"
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

# IAM Roles for Terrlocal.trusted_principal
data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "AllowTrustedPrincipals"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = local.trusted_principals
    }
  }
}

resource "aws_iam_role" "plan" {
  name               = "TerraformPlanOnly"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  description        = "Read-only Terraform planning role"
}

resource "aws_iam_role" "apply" {
  name               = "TerraformApplyOnly"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  description        = "Terraform apply role with write permissions"
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
