resource "aws_iam_openid_connect_provider" "this" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]
}

resource "aws_iam_role" "github_deploy" {
  name = "kb-pipeline-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.this.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          # StringLike so the * wildcard matches any environment name (dev, test, prod)
          StringLike = {
            "token.actions.githubusercontent.com:sub" = var.github_subs
          }
        }
      }
    ]
  })
}

# Read-only view of the account, enough for terraform plan
resource "aws_iam_role_policy_attachment" "read_only" {
  role       = aws_iam_role.github_deploy.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Plus: use the Terraform state (read, write, lock) and read the Snowflake key secret.
resource "aws_iam_role_policy" "github_deploy" {
  name = "kb-pipeline-state-and-secrets"
  role = aws_iam_role.github_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${var.state_bucket}"
      },
      {
        # Write and delete are needed for the state file and its lock file
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::${var.state_bucket}/*"
      },
      {
        # The state bucket is encrypted with KMS
        Effect    = "Allow"
        Action    = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource  = "*"
        Condition = { StringEquals = { "kms:ViaService" = "s3.${var.region}.amazonaws.com" } }
      },
      {
        # Create and manage the landing buckets (and their files), only buckets with the project prefix
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          "arn:aws:s3:::${var.landing_bucket_prefix}*",
          "arn:aws:s3:::${var.landing_bucket_prefix}*/*",
        ]
      },
      {
        # Create and manage KMS keys. CreateKey cannot be limited to a resource, so these apply to all keys.
        Effect = "Allow"
        Action = [
          "kms:CreateKey", "kms:CreateAlias", "kms:DeleteAlias", "kms:UpdateAlias",
          "kms:EnableKeyRotation", "kms:DisableKeyRotation", "kms:PutKeyPolicy",
          "kms:TagResource", "kms:UntagResource", "kms:ScheduleKeyDeletion", "kms:CancelKeyDeletion",
        ]
        Resource = "*"
      },
      {
        # Create and manage the roles Snowflake assumes, only roles with the project prefix
        Effect = "Allow"
        Action = [
          "iam:CreateRole", "iam:DeleteRole", "iam:UpdateRole", "iam:UpdateAssumeRolePolicy",
          "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:TagRole", "iam:UntagRole",
        ]
        Resource = "arn:aws:iam::*:role/${var.snowflake_role_prefix}*"
      },
      {
        # Read the Snowflake private key secret, nothing else in Secrets Manager (names end in a random -suffix)
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [for name in var.secret_names : "arn:aws:secretsmanager:${var.region}:*:secret:${name}-*"]
      }
    ]
  })
}
