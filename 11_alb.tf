resource "aws_lb" "main" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"

  # TODO: ALB의 보안 그룹과 서브넷 연결
  security_groups = [aws_security_group.alb.id]
  subnets         = aws_subnet.public[*].id
  # TODO: public subnet 모두에 골고루 배치되도록 서브넷 연결

  tags = {
    Name = "${var.name}-alb"
  }
}

resource "aws_lb_listener" "main" {
  # TODO: ALB에 기본 80 포트 / 아무 rule 과 매칭 안되었을때 403 에러를 띄워 임의 접근을 차단
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }
}