terraform {
  required_version = ">= 1.10.0" # S3 native state locking (use_lockfile) needs 1.10+

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Real AWS, using the terraform-admin profile from ~/.aws/credentials.
provider "aws" {
  region  = var.region
  profile = "terraform-admin"
}
