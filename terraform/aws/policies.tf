# Snowflake role may only read the transactions/ files
resource "aws_iam_role_policy" "snowflake_access" {
  name = "read-landing-transactions"
  role = aws_iam_role.snowflake_access.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Read the files (GetObjectVersion because the bucket is versioned)
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource = "${aws_s3_bucket.landing.arn}/transactions/*"
      },
      {
        # Decrypt the KMS-encrypted files
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = aws_kms_key.landing.arn
      },
      {
        # List the bucket, limited to transactions/
        Effect    = "Allow"
        Action    = ["s3:ListBucket"]
        Resource  = aws_s3_bucket.landing.arn
        Condition = { StringLike = { "s3:prefix" = ["transactions/*"] } }
      }
    ]
  })
}
