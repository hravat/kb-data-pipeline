# T06: landing bucket
resource "aws_s3_bucket" "landing" {
  bucket = var.landing_bucket
}

resource "aws_s3_bucket_versioning" "landing" {
  bucket = aws_s3_bucket.landing.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "landing" {
  bucket = aws_s3_bucket.landing.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# T07: event notification, new files under transactions/ go to an SQS queue
resource "aws_sqs_queue" "landing_events" {
  name = "${var.landing_bucket}-events"
}

resource "aws_sqs_queue_policy" "landing_events" {
  queue_url = aws_sqs_queue.landing_events.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.landing_events.arn
        Condition = {
          ArnEquals = { "aws:SourceArn" = aws_s3_bucket.landing.arn }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "landing" {
  bucket = aws_s3_bucket.landing.id

  queue {
    queue_arn     = aws_sqs_queue.landing_events.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "transactions/"
  }

  depends_on = [aws_sqs_queue_policy.landing_events]
}
