# ─── Application Load Balancer ───────────────────────────────────────────────

resource "aws_lb" "this" {
  name               = "${var.app_name}-${var.env}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.app_name}-${var.env}-alb"
  }
}

# ─── Target Group ─────────────────────────────────────────────────────────────
# target_type = "ip" vì Fargate tasks dùng awsvpc network mode

resource "aws_lb_target_group" "this" {
  name        = "${var.app_name}-${var.env}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = var.health_check_path
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Name = "${var.app_name}-${var.env}-tg"
  }
}

# ─── Listener ────────────────────────────────────────────────────────────────

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
