module "aws" {
  source = "./aws"

  landing_bucket = var.landing_bucket
}

module "snowflake" {
  source = "./snowflake"
}
