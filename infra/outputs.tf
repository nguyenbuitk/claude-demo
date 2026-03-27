output "alb_dns_name" {
  description = "ALB DNS name — dùng để truy cập app"
  value       = module.alb.alb_dns_name
}

output "ecr_url" {
  description = "ECR repository URL"
  value       = module.ecr.ecr_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs.service_name
}

output "db_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}
