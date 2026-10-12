output "state_bucket" {
  description = "Bucket to use in the backend \"s3\" block of other Terraform folders"
  value       = aws_s3_bucket.state.id
}
