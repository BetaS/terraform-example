resource "aws_security_group" "alb" {
  name = "${var.name}-alb-sg"
  vpc_id = aws_vpc.main.id
  
  # TODO: ALB에 들어오는 80, 443 포트의 모든 ingress 트래픽을 허용
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-alb-sg"
  }
}