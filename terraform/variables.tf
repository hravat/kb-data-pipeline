# AWS
variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "landing_bucket" {
  description = "Name of the S3 landing bucket (must be globally unique)"
  type        = string
  default     = "kb-data-pipeline-landing-hravat"
}

# Snowflake
variable "snowflake_organization_name" {
  description = "Snowflake organization name (first part of the account identifier)"
  type        = string
  default     = "OLEMHOV"
}

variable "snowflake_account_name" {
  description = "Snowflake account name (second part of the account identifier)"
  type        = string
  default     = "NY88954"
}

variable "snowflake_user" {
  description = "Snowflake login name Terraform connects as"
  type        = string
  default     = "HUSSAIN.RAVAT.NZ@GMAIL.COM"
}

variable "snowflake_role" {
  description = "Role Terraform uses (ACCOUNTADMIN is needed for the storage integration)"
  type        = string
  default     = "ACCOUNTADMIN"
}

variable "snowflake_private_key_path" {
  description = "Path to the PKCS#8 private key (.p8) for key-pair auth. Keep it outside the repo."
  type        = string
  default     = "~/.snowflake/rsa_key.p8"
}
