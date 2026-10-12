variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "state_bucket" {
  description = "Name of the S3 bucket that holds Terraform state (must be globally unique)"
  type        = string
  default     = "kb-data-pipeline-tfstate-hravat"
}
