resource "aws_security_group" "alb" {
  name = "${var.name}-alb-sg"
  
  # TODO: ALB에 들어오는 80, 443 포트의 모든 ingress 트래픽을 허용

  tags = {
    Name = "${var.name}-alb-sg"
  }
}