resource "aws_ecs_cluster" "this" {
    name = "${var.app_name}-${var.env}-cluster"
    tags = { Name = "${var.app_name}-${var.env}-cluster" }
}

resource "aws_cloudwatch_log_group" "this" {
    name              = "/ecs/${var.app_name}-${var.env}"
    retention_in_days = 7
}

resource "aws_ecs_task_definition" "this" {
    family                   = "${var.app_name}-${var.env}"
    requires_compatibilities = ["FARGATE"]
    network_mode             = "awsvpc"
    cpu                      = 256
    memory                   = 512
    execution_role_arn       = var.task_execution_role_arn

    container_definitions = jsonencode([{
        name  = var.app_name
        image = "${var.ecr_image_url}:latest"

        portMappings = [{
            containerPort = 5000
            protocol      = "tcp"
        }]

        environment = [
            { name = "DB_HOST",   value = var.db_host },
            { name = "DB_PORT",   value = "5432" },
            { name = "DB_NAME",   value = var.db_name },
            { name = "DB_USER",   value = var.db_username },
            { name = "FLASK_ENV", value = "production" }
        ]

        secrets = [{
            name      = "DB_PASSWORD"
            valueFrom = "${var.secret_arn}:password::"
        }]

        healthCheck = {
            command     = ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:5000/health')\" || exit 1"]
            interval    = 30
            timeout     = 5
            retries     = 3
            startPeriod = 60
        }

        logConfiguration = {
            logDriver = "awslogs"
            options = {
                "awslogs-group"         = aws_cloudwatch_log_group.this.name
                "awslogs-region"        = "ap-southeast-1"
                "awslogs-stream-prefix" = "ecs"
            }
        }
    }])
}

resource "aws_ecs_service" "this" {
    name            = "${var.app_name}-${var.env}-svc"
    cluster         = aws_ecs_cluster.this.id
    task_definition = aws_ecs_task_definition.this.arn
    desired_count   = 1
    launch_type     = "FARGATE"

    network_configuration {
        subnets          = var.private_subnet_ids
        security_groups  = [var.ecs_sg_id]
        assign_public_ip = false
    }

    load_balancer {
        target_group_arn = var.target_group_arn
        container_name   = var.app_name
        container_port   = 5000
    }
}
