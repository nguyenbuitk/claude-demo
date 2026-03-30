output "db_endpoint" {
    value = aws_db_instance.this.address
}

output "db_name" {
    value = aws_db_instance.this.db_name
}

output "db_username" {
    value = aws_db_instance.this.username
}

output "secret_arn" {
    value = aws_secretsmanager_secret.db.arn
}
