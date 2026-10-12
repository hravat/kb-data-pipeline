# No defaults: every value is supplied explicitly.
# CI: the workflow passes them from the GitHub environment (TF_VAR_<name>).
# Local: terraform.tfvars (gitignored); copy terraform.tfvars.example.

# AWS
variable "region" {
  description = "AWS region"
  type        = string
}

variable "landing_bucket" {
  description = "Name of the S3 landing bucket (must be globally unique)"
  type        = string
}

variable "snowflake_access_role_name" {
  description = "Name of the IAM role Snowflake assumes to read the landing bucket"
  type        = string
}

# Snowflake
variable "snowflake_organization_name" {
  description = "Snowflake organization name (first part of the account identifier)"
  type        = string
}

variable "snowflake_account_name" {
  description = "Snowflake account name (second part of the account identifier)"
  type        = string
}

variable "snowflake_user" {
  description = "Snowflake login name Terraform connects as"
  type        = string
}

variable "snowflake_role" {
  description = "Role Terraform uses (ACCOUNTADMIN is needed for the storage integration)"
  type        = string
}

variable "snowflake_private_key_path" {
  description = "Path to the PKCS#8 private key (.p8) for key-pair auth. Keep it outside the repo."
  type        = string
}

variable "database_name" {
  description = "Snowflake database for this environment"
  type        = string
}

# Set after the first run, from this environment's integration and pipe. Empty string means "not yet".
variable "snowflake_iam_user_arn" {
  description = "STORAGE_AWS_IAM_USER_ARN from DESC INTEGRATION. Empty until the integration exists."
  type        = string
}

variable "snowflake_external_id" {
  description = "STORAGE_AWS_EXTERNAL_ID from DESC INTEGRATION. Empty until the integration exists."
  type        = string
}

variable "snowpipe_queue_arn" {
  description = "notification_channel from SHOW PIPES (the Snowpipe SQS queue ARN). Empty until the pipe exists."
  type        = string
}
