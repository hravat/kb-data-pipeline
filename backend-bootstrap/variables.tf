variable "region" {
  description = "AWS region to use against Floci"
  type        = string
  default     = "us-east-1"
}

variable "floci_endpoint" {
  description = "Floci endpoint URL (use http://floci:4566 from inside the Compose network)"
  type        = string
  default     = "http://localhost:4566"
}

variable "state_bucket" {
  description = "Name of the S3 bucket that holds Terraform state (must be globally unique on real AWS)"
  type        = string
  default     = "kb-data-pipeline-tfstate"
}
