variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "env" {
  description = "Environment name (dev, prod)"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "claude-demo"
}

variable "github_org" {
  description = "GitHub organization/username for OIDC trust"
  type        = string
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "ecs_cpu" {
  description = "ECS task CPU units (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "ecs_memory" {
  description = "ECS task memory in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}
