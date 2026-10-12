terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.0"
    }
  }
}

# Real AWS, using the terraform-admin profile from ~/.aws/credentials.
provider "aws" {
  region  = var.region
  profile = "terraform-admin"
}

provider "snowflake" {
  organization_name = var.snowflake_organization_name
  account_name      = var.snowflake_account_name
  user              = var.snowflake_user
  role              = var.snowflake_role

  # Key-pair auth: no password, no MFA prompt. The key file lives outside the repo.
  authenticator = "SNOWFLAKE_JWT"
  private_key   = file(pathexpand(var.snowflake_private_key_path))
}
