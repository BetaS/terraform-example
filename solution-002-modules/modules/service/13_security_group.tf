resource aws_security_group "service" {
  name   = "ecs-task-${var.env}-${var.name}-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags   = {
      Name = "ecs-task-${var.env}-${var.name}-sg"
  }
}

resource "aws_security_group_rule" "lb_to_service_egress" {
  type              = "egress"
  from_port         = var.port
  to_port           = var.port
  source_security_group_id = aws_security_group.service.id
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
}