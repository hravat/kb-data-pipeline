variable "landing_bucket" {
  description = "Name of the S3 landing bucket"
  type        = string
}

# Set after the Snowflake storage integration exists (DESC INTEGRATION)
variable "snowflake_iam_user_arn" {
  description = "STORAGE_AWS_IAM_USER_ARN from DESC INTEGRATION. Empty until the integration exists."
  type        = string
  default     = ""
}

variable "snowflake_external_id" {
  description = "STORAGE_AWS_EXTERNAL_ID from DESC INTEGRATION. Placeholder until the integration exists."
  type        = string
  default     = "pending"
}

# Set after the Snowpipe exists (notification_channel from SHOW PIPES)
variable "snowpipe_queue_arn" {
  description = "notification_channel from SHOW PIPES (the Snowpipe SQS queue ARN). Empty until the pipe exists."
  type        = string
  default     = ""
}
