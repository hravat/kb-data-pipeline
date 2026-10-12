# State lives in the bucket created by ../backend-bootstrap (apply that first).
# The key is per environment and is passed at init, because backend blocks can't use variables:
#   terraform init -backend-config="key=terraform/dev/terraform.tfstate"
# Credentials: locally the AWS_PROFILE environment variable; in CI the OIDC credentials.
terraform {
  backend "s3" {
    bucket       = "kb-data-pipeline-tfstate-hravat"
    region       = "ap-southeast-2"
    use_lockfile = true
    encrypt      = true
  }
}
