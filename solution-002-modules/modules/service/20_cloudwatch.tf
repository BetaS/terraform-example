resource "aws_cloudwatch_log_group" "service" {
  name              = "/ecs/${var.env}/${var.name}"
  retention_in_days = 7
  tags = {
    Name = var.name
  }
}