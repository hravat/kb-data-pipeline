variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "github_sub" {
  description = "Token subject pattern allowed to assume the role: any branch of this repo. It includes numeric owner and repo IDs."
  type        = string
  default     = "repo:hravat@32519928/kb-data-pipeline@1414955736:ref:refs/heads/*"
}

variable "state_bucket" {
  description = "Terraform state bucket the role may read"
  type        = string
  default     = "kb-data-pipeline-tfstate-hravat"
}
