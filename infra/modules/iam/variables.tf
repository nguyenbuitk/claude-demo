variable "app_name" {
  description = "Application name"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or username (for OIDC trust policy)"
  type        = string
}

variable "rds_secret_arn" {
  description = "ARN of the RDS secret in Secrets Manager (for ECS task execution role)"
  type        = string
}
