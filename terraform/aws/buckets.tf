# T06: landing bucket for the uploaded transaction files
resource "aws_s3_bucket" "landing" {
  bucket = var.landing_bucket
}

# Keep old versions so a bad upload can be recovered
resource "aws_s3_bucket_versioning" "landing" {
  bucket = aws_s3_bucket.landing.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt at rest with the KMS key; bucket key cuts the number of KMS calls
resource "aws_s3_bucket_server_side_encryption_configuration" "landing" {
  bucket = aws_s3_bucket.landing.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.landing.arn
    }
  }
}

# T07: notify Snowpipe's queue when a file lands; only created once the pipe's queue ARN is known
resource "aws_s3_bucket_notification" "landing" {
  count  = var.snowpipe_queue_arn != "" ? 1 : 0
  bucket = aws_s3_bucket.landing.id

  queue {
    queue_arn     = var.snowpipe_queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "transactions/"
  }
}
