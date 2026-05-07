resource "aws_ecs_task_definition" "service" {
  family = "${var.env}-${var.name}"
  network_mode = "awsvpc"
  cpu = 512  # 0.5vCPU
  memory = 1024  # 1GB RAM
  lifecycle {
    ignore_changes = [container_definitions]
  }
  runtime_platform {
    # graviton 쓰게끔 arm64
    cpu_architecture = "ARM64"
    operating_system_family = "LINUX"
  }
  requires_compatibilities = ["FARGATE"]
  task_role_arn = aws_iam_role.task_role.arn
  execution_role_arn = data.aws_iam_role.execution_role.arn
  container_definitions = jsonencode([
    {
      name         = var.name
      image        = "${aws_ecr_repository.service.repository_url}:latest"
      networkMode  = "awsvpc"
      portMappings = [
        {
          name          = "http",
          containerPort = var.port,
          hostPort      = var.port,
          protocol      = "tcp",
          appProtocol   = "http"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.service.name
          "awslogs-region"        = "ap-northeast-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }])
}