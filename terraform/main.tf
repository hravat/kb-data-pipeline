# AWS: landing bucket, event notification, and the role Snowflake uses to read the bucket
module "aws" {
  source = "./aws"

  landing_bucket = var.landing_bucket

  # Empty until the Snowflake objects exist (see snowflake-sql/setup.sql)
  snowflake_iam_user_arn = var.snowflake_iam_user_arn
  snowflake_external_id  = var.snowflake_external_id
  snowpipe_queue_arn     = var.snowpipe_queue_arn
}

# Snowflake: database and schema; the rest is in snowflake-sql/setup.sql
module "snowflake" {
  source = "./snowflake"
}
