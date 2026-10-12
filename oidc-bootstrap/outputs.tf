output "github_deploy_role_arn" {
  description = "Role ARN to put in the GitHub repo variable AWS_ROLE_ARN"
  value       = aws_iam_role.github_deploy.arn
}
