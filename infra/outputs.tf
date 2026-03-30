output "alb_dns_name" {
    value       = module.alb.alb_dns_name
    description = "URL để truy cập app: http://<value>/health"
}

output "ecr_repository_url" {
    value       = module.ecr.repository_url
    description = "ECR URL để push Docker image"
}

output "github_actions_role_arn" {
    value       = module.iam.github_actions_role_arn
    description = "Role ARN dùng trong CI/CD workflow"
}
