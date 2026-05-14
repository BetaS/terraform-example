resource "aws_ecs_service" "service" {
  name                 = var.name
  cluster              = var.ecs_cluster_id
  task_definition      = aws_ecs_task_definition.service.arn
  desired_count        = 0 # 처음에 0으로 시작하고, 가동 준비가 완료되면 직접 1로 변경해준다.
  force_new_deployment = true
  network_configuration {
    security_groups  = [aws_security_group.service.id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.service.arn
    container_name   = var.name
    container_port   = var.port
  }
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # capacity_provider_strategy 총 2개 ~ 3개를 만들어줘야 하는데,
  # block 내에서 count를 쓸 수 없음
  # 이때 사용할 수 있는 예약 키워드가 dynamic 블록
  # capacity_provider_strategy를 dynamic하게 정의 하겠다는 뜻
  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategy
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      # lookup은 element의 key-value 버전, 3번째 parameter를 default 값으로 취급해서 null-safe 하게 만들어 줌
      base = lookup(capacity_provider_strategy.value, "base", null)
    }
  }

  lifecycle {
    # CI/CD에 의해 값이 변경되므로 매번 지우고 다시만드는것 방지하려고 예외 등록함
    # desired_count는 auto scaling group 에 의해서 매번 동적으로 변경
    # 코드상에는 1개를 적었지만, 실제로는 8개 떠있는 경우
    # ignore가 없으면, terraform apply 하는 순간 1개로 줄어듬 -> 서비스 장애 발생
    # task_definition -> github actions 로 새로 배포될 때 마다 버전이 1씩 증가하기 때문에
    # 자칫 잘못하면 최초 버전 (1버전) 으로 돌아갈 위험이 있음
    ignore_changes = [task_definition, desired_count]
  }
}