resource "aws_lb" "main" {
  name = "${var.name}-alb"
  internal = false
  load_balancer_type = "application"
  
  # TODO: ALB의 보안 그룹과 서브넷 연결
  # TODO: public subnet 모두에 골고루 배치되도록 서브넷 연결

  tags = {
    Name = "${var.name}-alb"
  }
}

resource "aws_lb_listener" "main" {
  # TODO: ALB에 기본 80 포트 / 아무 rule 과 매칭 안되었을때 403 에러를 띄워 임의 접근을 차단
}