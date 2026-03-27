output "ecr_url" {
  description = "ECR repository URL (dùng trong ECS task definition)"
  value       = aws_ecr_repository.this.repository_url
}

output "ecr_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.this.arn
}
