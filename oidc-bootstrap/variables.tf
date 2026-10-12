variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "github_repo" {
  description = "GitHub repository allowed to assume the deploy role (owner/name)"
  type        = string
  default     = "hravat/kb-data-pipeline"
}

variable "state_bucket" {
  description = "Terraform state bucket the role may read"
  type        = string
  default     = "kb-data-pipeline-tfstate-hravat"
}
