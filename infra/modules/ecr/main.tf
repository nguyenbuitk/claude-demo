resource "aws_ecr_repository" "this" {
    name                 = var.app_name
    image_tag_mutability = "MUTABLE"
    force_delete         = true

    tags = { Name = var.app_name }
}

resource "aws_ecr_lifecycle_policy" "this" {
    repository = aws_ecr_repository.this.name

    policy = jsonencode({
        rules = [{
            rulePriority = 1
            description  = "Keep last 10 images"
            selection = {
                tagStatus   = "any"
                countType   = "imageCountMoreThan"
                countNumber = 10
            }
            action = { type = "expire" }
        }]
    })
}
