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
