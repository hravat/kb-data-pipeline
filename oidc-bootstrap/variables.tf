variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "github_subs" {
  description = "Token subjects allowed to assume the role: any branch, or any GitHub environment, of this repo. Includes the numeric owner and repo IDs."
  type        = list(string)
  default = [
    "repo:hravat@32519928/kb-data-pipeline@1414955736:ref:refs/heads/*",
    "repo:hravat@32519928/kb-data-pipeline@1414955736:environment:*",
  ]
}

variable "state_bucket" {
  description = "Terraform state bucket the role may read and write"
  type        = string
  default     = "kb-data-pipeline-tfstate-hravat"
}

variable "secret_names" {
  description = "Names of the Secrets Manager secrets the role may read (the Snowflake private key)"
  type        = list(string)
  default     = ["SNOWFLAKE_PRIVATE_KEY"]
}

variable "landing_bucket_prefix" {
  description = "Prefix of the landing buckets the role may create and manage (one per environment)"
  type        = string
  default     = "kb-data-pipeline-landing-"
}

variable "snowflake_role_prefix" {
  description = "Prefix of the IAM roles Snowflake assumes, which the role may create and manage (one per environment)"
  type        = string
  default     = "kb-pipeline-snowflake-access-"
}
