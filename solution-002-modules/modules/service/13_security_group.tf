resource "aws_security_group" "service" {
  name   = "ecs-task-${var.env}-${var.name}-sg"
  vpc_id = var.vpc_id

  lifecycle {
    precondition {
      condition     = (var.rds_secret_arn == "" && var.rds_security_group_id == "") || (var.rds_secret_arn != "" && var.rds_security_group_id != "")
      error_message = "RDS 연동: rds_secret_arn과 rds_security_group_id는 둘 다 비우거나(API) 둘 다 지정하세요. 웹 서비스는 둘 다 비워 두세요."
    }
  }

  ingress {
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = [var.lb_sg_id]
  }

  # 웹: 001과 같이 외부는 443만 (RDS 5432로의 egress 없음 → 네트워크상으로도 DB 직접 접속 불가)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # API만 rds_security_group_id 전달 시 RDS로 PostgreSQL egress
  dynamic "egress" {
    for_each = var.rds_security_group_id != "" ? [1] : []
    content {
      description     = "PostgreSQL to RDS"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [var.rds_security_group_id]
    }
  }

  tags = {
    Name = "ecs-task-${var.env}-${var.name}-sg"
  }
}

resource "aws_security_group_rule" "lb_to_service_egress" {
  type                     = "egress"
  from_port                = var.port
  to_port                  = var.port
  source_security_group_id = aws_security_group.service.id
  protocol                 = "tcp"
  security_group_id        = var.lb_sg_id
}
