locals {
  api_port = 7777
}

resource aws_cloudwatch_log_group "api-server" {
  name              = "/ecs/${var.name}-api-server"
  retention_in_days = 7
  tags = {
    Name        = "${var.name}-api-server"
  }
}

resource "aws_ecr_repository" "api-server" {
  name = "${var.name}-api-server"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecs_task_definition" "api-server" {
  family = "${var.name}-api-server"
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
  task_role_arn = aws_iam_role.task_role_api.arn
  execution_role_arn = aws_iam_role.execution_role.arn
  container_definitions = jsonencode([
    {
      name         = var.name
      image        = "${aws_ecr_repository.api-server.repository_url}:latest"
      networkMode  = "awsvpc"
      portMappings = [
        {
          name          = "http",
          containerPort = local.api_port,
          hostPort      = local.api_port,
          protocol      = "tcp",
          appProtocol   = "http"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.api-server.name
          "awslogs-region"        = "ap-northeast-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }])
}

resource "aws_ecs_service" "api-server" {
  name = "${var.name}-api-server"

  # TODO: ECS 서비스 생성
  # 1. 클러스터에 연결하고
  # 2. 태스크 정의와 연결하고
  # 3. 원하는 갯수 (일단 0개)만큼 실행하고
  # 4. 네트워크 설정을 해주고
  # 5. 로드밸런서와 연결하고
  # 6. 용량 전략(FARGATE_SPOT)을 설정한다.

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

resource aws_security_group "api-server" {
  name   = "ecs-task-${var.name}-api-server-sg"
  vpc_id = aws_vpc.main.id

  # TODO: ALB -> API ECS 태스크에 들어오는 tcp 트래픽을 허용

  tags   = {
      Name = "ecs-task-${var.name}-api-server-sg"
  }
}

# API ECS 태스크에만 부착 — RDS는 서브넷 CIDR이 아니라 이 SG를 가진 ENI(워크로드 식별)에서만 5432 허용
resource "aws_security_group" "ecs_api_rds_client" {
  name   = "${var.name}-ecs-api-rds-client-sg"
  vpc_id = aws_vpc.main.id

  # TODO: API ECS 태스크에서 RDS로의 tcp 트래픽을 허용

  tags = {
    Name = "${var.name}-ecs-api-rds-client-sg"
  }
}

resource "aws_security_group_rule" "lb_to_api_server_egress" {
  security_group_id = aws_security_group.alb.id
  # TODO: ALB에서 API ECS 태스크로의 tcp 트래픽 egress을 허용
}

resource "aws_lb_target_group" "api-server" {
  name                  = "alb-tg-${var.name}-api-server"

  # TODO: lb target group 생성
  # 1. listen port 등록
  # 2. health check 방식 설정
  # 3. deregistration delay 설정 (30s로 설정해야 spot instance가 SIGTERM을 받았을 때, 컨테이너가 종료되기 전에 ALB에서 먼저 제거되도록 설정)

  lifecycle {
    create_before_destroy = true
  }
}

resource aws_lb_listener_rule "api-server" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100

  # TODO: 특정 경로 (/api/*) 일때 ALB -> API ECS 태스크로의 tcp 트래픽 forward 설정
}

resource "aws_iam_role" "task_role_api" {
  name = "ecsTaskRole-${var.name}-api"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}