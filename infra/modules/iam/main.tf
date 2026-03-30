# ECS Task Execution Role — cho phép ECS pull image từ ECR và đọc Secrets Manager
resource "aws_iam_role" "ecs_task_execution" {
    name = "${var.app_name}-ecs-task-execution-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect    = "Allow"
            Principal = { Service = "ecs-tasks.amazonaws.com" }
            Action    = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
    role       = aws_iam_role.ecs_task_execution.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_secrets" {
    name = "${var.app_name}-ecs-secrets-policy"
    role = aws_iam_role.ecs_task_execution.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect   = "Allow"
            Action   = ["secretsmanager:GetSecretValue"]
            Resource = "*"
        }]
    })
}

# GitHub Actions OIDC — cho phép CI/CD push ECR và deploy ECS mà không cần AWS keys
resource "aws_iam_openid_connect_provider" "github" {
    url             = "https://token.actions.githubusercontent.com"
    client_id_list  = ["sts.amazonaws.com"]
    thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions" {
    name = "${var.app_name}-github-actions-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = {
                Federated = aws_iam_openid_connect_provider.github.arn
            }
            Action = "sts:AssumeRoleWithWebIdentity"
            Condition = {
                StringLike = {
                    "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
                }
                StringEquals = {
                    "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
                }
            }
        }]
    })
}

resource "aws_iam_role_policy" "github_actions" {
    name = "${var.app_name}-github-actions-policy"
    role = aws_iam_role.github_actions.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "ecr:GetAuthorizationToken",
                    "ecr:BatchCheckLayerAvailability",
                    "ecr:GetDownloadUrlForLayer",
                    "ecr:BatchGetImage",
                    "ecr:PutImage",
                    "ecr:InitiateLayerUpload",
                    "ecr:UploadLayerPart",
                    "ecr:CompleteLayerUpload"
                ]
                Resource = "*"
            },
            {
                Effect   = "Allow"
                Action   = ["ecs:UpdateService", "ecs:DescribeServices"]
                Resource = "*"
            }
        ]
    })
}
