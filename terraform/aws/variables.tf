# Passed in from the root module (terraform/main.tf).

variable "landing_bucket" {
  description = "Name of the S3 landing bucket"
  type        = string
}

variable "snowflake_access_role_name" {
  description = "Name of the IAM role Snowflake assumes to read the landing bucket"
  type        = string
}

# Set after the Snowflake storage integration exists (DESC INTEGRATION). Empty means "not yet".
variable "snowflake_iam_user_arn" {
  description = "STORAGE_AWS_IAM_USER_ARN from DESC INTEGRATION. Empty until the integration exists."
  type        = string
}

variable "snowflake_external_id" {
  description = "STORAGE_AWS_EXTERNAL_ID from DESC INTEGRATION. Empty until the integration exists."
  type        = string
}

# Set after the Snowpipe exists (notification_channel from SHOW PIPES). Empty means "not yet".
variable "snowpipe_queue_arn" {
  description = "notification_channel from SHOW PIPES (the Snowpipe SQS queue ARN). Empty until the pipe exists."
  type        = string
}
