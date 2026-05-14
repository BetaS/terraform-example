resource "aws_lb_target_group" "service" {
  vpc_id               = var.vpc_id
  name                 = "alb-tg-${var.env}-${var.name}"
  port                 = var.port
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = 30 # 중요 spot instance가 SIGTERM을 받았을 때, 컨테이너가 종료되기 전에 ALB에서 먼저 제거되도록 설정

  health_check {
    interval            = 120
    path                = var.lb_health_check_path
    timeout             = 60
    matcher             = "200-299"
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener_rule" "service" {
  listener_arn = var.lb_listener_arn
  priority     = var.lb_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service.arn
  }

  condition {
    path_pattern {
      values = var.lb_path_prefix
    }
  }
}