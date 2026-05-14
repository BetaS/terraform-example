resource "aws_security_group" "rds" {
  name   = "${var.name}-rds-sg"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-rds-sg"
  }
}

# cycle dependency 방지를 위해, 그룹을 먼저 정의하고, 그 다음에 보안 그룹 규칙을 정의
resource "aws_security_group_rule" "rds_from_api_ingress" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds.id
  from_port                = aws_db_instance.rds.port
  to_port                  = aws_db_instance.rds.port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.api-server.id
}
