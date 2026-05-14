locals {
  dev_vpc_cidr     = "10.200.0.0/16"
  dev_private_cidr = "10.200.100.0/24"
  dev_zones        = ["ap-northeast-2a"]
}

resource "aws_iam_role" "ecs_execution_dev" {
  name = "ecsTaskExecutionRole-service-dev"

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

resource "aws_iam_role_policy_attachment" "ecs_execution_dev" {
  role       = aws_iam_role.ecs_execution_dev.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

module "dev-network" {
  source       = "./modules/network"
  name         = "dev"
  vpc_cidr     = local.dev_vpc_cidr
  private_cidr = local.dev_private_cidr
  zones        = local.dev_zones
  providers = {
    aws.global = aws.global
  }
}

module "dev-rds" {
  source      = "./modules/database"
  name        = "service-dev"
  db_username = "db_user"
  vpc_id      = module.dev-network.id
  zones       = ["ap-northeast-2a", "ap-northeast-2c"]
  cidr_block  = "10.200.200.0/23"
  multi_az    = false
}

resource "aws_ecs_cluster" "dev-cluster" {
  name = "service-dev"
}

module "dev-web-server" {
  env                  = "dev"
  source               = "./modules/service"
  name                 = "web-server"
  vpc_id               = module.dev-network.id
  ecs_cluster_id       = aws_ecs_cluster.dev-cluster.id
  execution_role_arn   = aws_iam_role.ecs_execution_dev.arn
  subnet_ids           = module.dev-network.private_subnet_ids
  lb_listener_arn      = module.dev-network.lb_listener_arn
  lb_sg_id             = module.dev-network.lb_sg_id
  lb_path_prefix       = ["/*"]
  lb_health_check_path = "/"
  lb_priority          = 2
  cpu                  = 256 # 256 CPU units = 0.25 vCPU
  memory               = 512 # 512 MiB
  port                 = 3000
  capacity_provider_strategy = [{
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }]
}

module "dev-api-server" {
  env                   = "dev"
  source                = "./modules/service"
  name                  = "api-server"
  vpc_id                = module.dev-network.id
  ecs_cluster_id        = aws_ecs_cluster.dev-cluster.id
  execution_role_arn    = aws_iam_role.ecs_execution_dev.arn
  subnet_ids            = module.dev-network.private_subnet_ids
  lb_listener_arn       = module.dev-network.lb_listener_arn
  lb_sg_id              = module.dev-network.lb_sg_id
  lb_path_prefix        = ["/api/", "/api/*"]
  lb_priority           = 1
  lb_health_check_path  = "/api/check"
  cpu                   = 512
  memory                = 1024
  port                  = 7777
  rds_secret_arn        = module.dev-rds.secret_arn
  rds_security_group_id = module.dev-rds.security_group.id
  capacity_provider_strategy = [{
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }]
  allow_ips = module.dev-network.nat_gw_ips # NAT GW만 허용
}

resource "aws_security_group_rule" "api-server-to-rds-ingress-dev" {
  security_group_id        = module.dev-rds.security_group.id
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.dev-api-server.security_group.id
}

# solution-001-3tier/output.tf와 동일한 키(vpc_id, web_env, api_env, cloudfront_url)를 하나의 객체로 묶음
output "dev" {
  value = {
    vpc_id = module.dev-network.id
    web_env = {
      actions_arn    = aws_iam_role.github_actions.arn
      ecr_name       = module.dev-web-server.ecr_name
      ecs_cluster    = aws_ecs_cluster.dev-cluster.name
      ecs_service    = module.dev-web-server.ecs_service_name
      container_name = module.dev-web-server.container_name
      task_name      = module.dev-web-server.task_family
    }
    api_env = {
      actions_arn    = aws_iam_role.github_actions.arn
      ecr_name       = module.dev-api-server.ecr_name
      ecs_cluster    = aws_ecs_cluster.dev-cluster.name
      ecs_service    = module.dev-api-server.ecs_service_name
      container_name = module.dev-api-server.container_name
      task_name      = module.dev-api-server.task_family
    }
    cloudfront_url = module.dev-network.cloudfront_domain_name
  }
}