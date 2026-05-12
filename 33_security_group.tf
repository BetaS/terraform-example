resource "aws_security_group" "rds" {
  name   = "${var.name}-rds-sg"
  vpc_id = aws_vpc.main.id

  # 외부로 나가는 트래픽을 차단하는것이 보안에 좋음
  #   egress {
  #     from_port   = 0
  #     to_port     = 0
  #     protocol    = "-1"
  #     cidr_blocks = []
  #   }

  tags = {
    Name = "${var.name}-rds-sg"
  }
}

resource "aws_security_group_rule" "rds_from_api_ingress" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.api-server.id
}
