# State lives in the bucket created by ../backend-bootstrap (apply that first).
# Backend blocks can't use variables, so the values are written out.
terraform {
  backend "s3" {
    bucket       = "kb-data-pipeline-tfstate-hravat"
    key          = "terraform/terraform.tfstate"
    region       = "ap-southeast-2"
    use_lockfile = true
    encrypt      = true
    profile      = "terraform-admin"
  }
}
