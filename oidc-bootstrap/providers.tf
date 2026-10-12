terraform {
  required_version = ">= 1.5.0"

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
