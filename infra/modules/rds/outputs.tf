output "db_endpoint" {
  description = "RDS endpoint hostname (không có port)"
  value       = aws_db_instance.this.address
}

output "db_secret_arn" {
  description = "Secrets Manager secret ARN (dùng trong ECS task definition)"
  value       = aws_secretsmanager_secret.db_password.arn
}
