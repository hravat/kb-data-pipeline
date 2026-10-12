# Used to build this account's ARN for the temporary trust policy
data "aws_caller_identity" "current" {}

# Role Snowflake assumes to read the bucket; trust is filled in after DESC INTEGRATION
resource "aws_iam_role" "snowflake_access" {
  name = var.snowflake_access_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        # Snowflake's IAM user once known, otherwise this account
        Principal = {
          AWS = var.snowflake_iam_user_arn != "" ? var.snowflake_iam_user_arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
        # External ID from the integration stops anyone else using this role ("pending" until it exists)
        Condition = { StringEquals = { "sts:ExternalId" = coalesce(var.snowflake_external_id, "pending") } }
      }
    ]
  })
}
