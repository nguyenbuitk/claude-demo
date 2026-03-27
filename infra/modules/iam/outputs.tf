output "task_execution_role_arn" {
  description = "ECS Task Execution Role ARN (dùng trong ECS task definition)"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "github_actions_role_arn" {
  description = "GitHub Actions Role ARN (dùng trong ci.yml)"
  value       = aws_iam_role.github_actions.arn
}
