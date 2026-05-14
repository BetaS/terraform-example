locals {
  prod_vpc_cidr     = "10.100.0.0/16"
  prod_private_cidr = "10.100.100.0/24"
  prod_zones        = ["ap-northeast-2a", "ap-northeast-2c"]
}


resource "aws_iam_role" "ecs_execution_prod" {
  name = "ecsTaskExecutionRole-service-prod"

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

resource "aws_iam_role_policy_attachment" "ecs_execution_prod" {
  role       = aws_iam_role.ecs_execution_prod.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

module "prod-network" {
  source       = "./modules/network"
  name         = "prod"
  vpc_cidr     = local.prod_vpc_cidr
  private_cidr = local.prod_private_cidr
  zones        = local.prod_zones
  providers = {
    aws.global = aws.global
  }
}

module "prod-rds" {
  source      = "./modules/database"
  name        = "service-prod"
  db_username = "db_user"
  vpc_id      = module.prod-network.id
  zones       = local.prod_zones
  cidr_block  = "10.100.200.0/23"
  multi_az    = true
}

resource "aws_ecs_cluster" "prod-cluster" {
  name = "service-prod"
}

module "prod-api-server" {
  source                = "./modules/service"
  env                   = "prod"
  name                  = "api-server"
  vpc_id                = module.prod-network.id
  ecs_cluster_id        = aws_ecs_cluster.prod-cluster.id
  execution_role_arn    = aws_iam_role.ecs_execution_prod.arn
  subnet_ids            = module.prod-network.private_subnet_ids
  lb_listener_arn       = module.prod-network.lb_listener_arn
  lb_sg_id              = module.prod-network.lb_sg_id
  lb_path_prefix        = ["/api/", "/api/*"]
  lb_health_check_path  = "/api/check"
  lb_priority           = 1
  cpu                   = 1024
  memory                = 2048
  port                  = 7777
  rds_secret_arn        = module.prod-rds.secret_arn
  rds_security_group_id = module.prod-rds.security_group.id
  capacity_provider_strategy = [{
    capacity_provider = "FARGATE"
    base              = 1
    weight            = 1
    }, {
    capacity_provider = "FARGATE_SPOT"
    weight            = 4
  }]
  allow_ips = module.prod-network.nat_gw_ips # NAT GW만 허용
}

resource "aws_security_group_rule" "api-server-to-rds-ingress-prod" {
  security_group_id        = module.prod-rds.security_group.id
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.prod-api-server.security_group.id
}

module "prod-web-server" {
  source               = "./modules/service"
  env                  = "prod"
  name                 = "web-server"
  vpc_id               = module.prod-network.id
  ecs_cluster_id       = aws_ecs_cluster.prod-cluster.id
  execution_role_arn   = aws_iam_role.ecs_execution_prod.arn
  subnet_ids           = module.prod-network.private_subnet_ids
  lb_listener_arn      = module.prod-network.lb_listener_arn
  lb_sg_id             = module.prod-network.lb_sg_id
  lb_path_prefix       = ["/*"]
  lb_health_check_path = "/"
  lb_priority          = 2
  cpu                  = 512  # 512 CPU units = 0.5 vCPU
  memory               = 1024 # 1024 MiB
  port                 = 3000
  capacity_provider_strategy = [{
    capacity_provider = "FARGATE"
    base              = 1
    weight            = 1
    }, {
    capacity_provider = "FARGATE_SPOT"
    weight            = 4
  }]
}

# solution-001-3tier/output.tf와 동일한 키(vpc_id, web_env, api_env, cloudfront_url)를 하나의 객체로 묶음
output "prod" {
  value = {
    vpc_id = module.prod-network.id
    web_env = {
      actions_arn    = aws_iam_role.github_actions.arn
      ecr_name       = module.prod-web-server.ecr_name
      ecs_cluster    = aws_ecs_cluster.prod-cluster.name
      ecs_service    = module.prod-web-server.ecs_service_name
      container_name = module.prod-web-server.container_name
      task_name      = module.prod-web-server.task_family
    }
    api_env = {
      actions_arn    = aws_iam_role.github_actions.arn
      ecr_name       = module.prod-api-server.ecr_name
      ecs_cluster    = aws_ecs_cluster.prod-cluster.name
      ecs_service    = module.prod-api-server.ecs_service_name
      container_name = module.prod-api-server.container_name
      task_name      = module.prod-api-server.task_family
    }
    cloudfront_url = module.prod-network.cloudfront_domain_name
  }
}