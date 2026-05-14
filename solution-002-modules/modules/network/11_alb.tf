resource "aws_lb" "main" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  # concat으로 default & public 모두에 골고루 배치되도록
  subnets = length(aws_subnet.public) > 1 ? [for x in aws_subnet.public : x.id] : [aws_subnet.default.id, aws_subnet.public[0].id] # aws_subnet.public[*].id

  tags = {
    Name = "${var.name}-alb"
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"

  # 기본적으로 모든 요청을 차단하고, 추후 허용해주는 rule에 의해서만 등록해준다.
  # ALB 가 아무 도메인 또는 AWS Internal 도메인으로 요청받는 경우가 있을 수 있기 때문에, 허용된 필드만 받도록 처리 해주는 것
  default_action {
    type = "fixed-response"

    fixed_response {
      status_code  = 403
      content_type = "text/plain"
      message_body = "Forbidden"
    }
  }
}