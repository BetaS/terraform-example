locals {
  api_port = 7777
}

resource "aws_cloudwatch_log_group" "api-server" {
  name              = "/ecs/${var.name}-api-server"
  retention_in_days = 7
  tags = {
    Name = "${var.name}-api-server"
  }
}

resource "aws_ecr_repository" "api-server" {
  name                 = "${var.name}-api-server"
  image_tag_mutability = "MUTABLE"
  force_delete = true
  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecs_task_definition" "api-server" {
  family       = "${var.name}-api-server"
  network_mode = "awsvpc"
  cpu          = 512  # 0.5vCPU
  memory       = 1024 # 1GB RAM
  runtime_platform {
    # amd64/x86_64 이미지 사용
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.task_role_api.arn
  execution_role_arn       = aws_iam_role.execution_role.arn
  container_definitions = jsonencode([
    {
      name        = "${var.name}-api-server"
      image       = "${aws_ecr_repository.api-server.repository_url}:latest"
      networkMode = "awsvpc"
      environment = [
        {
          name  = "RDS_SECRET_ARN"
          value = aws_secretsmanager_secret.rds.arn
        }
      ]
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
  cluster              = aws_ecs_cluster.cluster.id
  task_definition      = aws_ecs_task_definition.api-server.arn
  desired_count        = 0 # 처음에 0으로 시작하고, 가동 준비가 완료되면 직접 1로 변경해준다.
  force_new_deployment = true
  network_configuration {
    security_groups  = [aws_security_group.api-server.id]
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.api-server.arn
    container_name   = "${var.name}-api-server"
    container_port   = local.api_port
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    base              = 1
    weight            = 1
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

resource "aws_security_group" "api-server" {
  name   = "ecs-task-${var.name}-api-server-sg"
  vpc_id = aws_vpc.main.id

  # TODO: ALB -> API ECS 태스크에 들어오는 tcp 트래픽을 허용
  ingress {
    from_port       = local.api_port
    to_port         = local.api_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.rds.id]
  }

  tags = {
    Name = "ecs-task-${var.name}-api-server-sg"
  }
}

resource "aws_security_group_rule" "lb_to_api_server_egress" {
  security_group_id = aws_security_group.alb.id
  # TODO: ALB에서 API ECS 태스크로의 tcp 트래픽 egress을 허용

  type                     = "egress"
  from_port                = local.api_port
  to_port                  = local.api_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.api-server.id
}

resource "aws_lb_target_group" "api-server" {
  name   = "alb-tg-${var.name}-api-server"
  vpc_id = aws_vpc.main.id

  # TODO: lb target group 생성
  # 1. listen port 등록
  # 2. health check 방식 설정
  # 3. deregistration delay 설정 (30s로 설정해야 spot instance가 SIGTERM을 받았을 때, 컨테이너가 종료되기 전에 ALB에서 먼저 제거되도록 설정)
  port                 = local.api_port
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = 30 # 중요 spot instance가 SIGTERM을 받았을 때, 컨테이너가 종료되기 전에 ALB에서 먼저 제거되도록 설정

  health_check {
    interval            = 120
    path                = "/"
    timeout             = 60
    matcher             = "200-299"
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener_rule" "api-server" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100

  # TODO: 특정 경로 (/api/*) 일때 ALB -> API ECS 태스크로의 tcp 트래픽 forward 설정
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api-server.arn
  }

  condition {
    path_pattern {
      values = ["/api/", "/api/*"]
    }
  }
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

resource "aws_iam_role_policy" "task_role_api_rds_secret" {
  name = "ecsTaskRole-${var.name}-api-rds-secret"
  role = aws_iam_role.task_role_api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.rds.arn
      }
    ]
  })
}
