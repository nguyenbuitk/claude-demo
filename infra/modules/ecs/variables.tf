variable "app_name" {
    type = string
}

variable "env" {
    type = string
}

variable "private_subnet_ids" {
    type = list(string)
}

variable "ecs_sg_id" {
    type = string
}

variable "target_group_arn" {
    type = string
}

variable "task_execution_role_arn" {
    type = string
}

variable "ecr_image_url" {
    type = string
}

variable "db_host" {
    type = string
}

variable "db_name" {
    type = string
}

variable "db_username" {
    type = string
}

variable "secret_arn" {
    type = string
}
