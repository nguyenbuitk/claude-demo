resource "aws_lb" "this" {
    name               = "${var.app_name}-${var.env}-alb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [var.alb_sg_id]
    subnets            = var.public_subnet_ids

    tags = { Name = "${var.app_name}-${var.env}-alb" }
}

resource "aws_lb_target_group" "this" {
    name        = "${var.app_name}-${var.env}-tg"
    port        = 5000
    protocol    = "HTTP"
    vpc_id      = var.vpc_id
    target_type = "ip"

    health_check {
        path                = "/health"
        healthy_threshold   = 2
        unhealthy_threshold = 3
        interval            = 30
        timeout             = 5
    }

    tags = { Name = "${var.app_name}-${var.env}-tg" }
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.this.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.this.arn
    }
}
