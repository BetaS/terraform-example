resource "aws_ecs_task_definition" "service" {
  family       = "${var.env}-${var.name}"
  network_mode = "awsvpc"
  cpu          = var.cpu
  memory       = var.memory
  lifecycle {
    ignore_changes = [container_definitions]
  }
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.task_role.arn
  execution_role_arn       = var.execution_role_arn
  container_definitions = jsonencode([
    merge(
      {
        name        = var.name
        image       = "${aws_ecr_repository.service.repository_url}:latest"
        networkMode = "awsvpc"
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
      },
      var.rds_secret_arn != "" && var.rds_security_group_id != "" ? {
        environment = [
          {
            name  = "RDS_SECRET_ARN"
            value = var.rds_secret_arn
          }
        ]
      } : {}
    )
  ])
}