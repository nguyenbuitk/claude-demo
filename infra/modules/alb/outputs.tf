output "alb_dns_name" {
  description = "ALB DNS name — dùng để truy cập app"
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "Target Group ARN (dùng trong ECS service)"
  value       = aws_lb_target_group.this.arn
}
