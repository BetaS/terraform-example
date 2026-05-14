resource "aws_security_group" "rds" {
  name   = "${var.name}-rds-sg"
  vpc_id = var.vpc_id

  #   egress {
  #     # 외부로 나가는 트래픽을 차단하는것이 보안에 좋음
  #     from_port   = 0
  #     to_port     = 0
  #     protocol    = "-1"
  #     cidr_blocks = []
  #   }

  tags = {
    Name = "${var.name}-rds-sg"
  }
}
