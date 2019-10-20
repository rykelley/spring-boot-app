output "ecr_repo_arns" {
  value = aws_ecr_repository.repos.*.arn
}

output "ecr_repo_urls" {
  value = aws_ecr_repository.repos.*.repository_url
}
