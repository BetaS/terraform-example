locals {
  prod_zones = ["ap-northeast-2a", "ap-northeast-2c"]
}

module "prod-network" {
  source    = "./modules/network"
  name      = "prod"
  vpc_cidr  = "10.100.0.0/16"
  private_cidr = "10.100.100.0/24"
  zones     = local.prod_zones
  providers = {
    aws.global = aws.global
  }
}

module "prod-rds" {
  source = "./modules/database"
  name   = "service-prod"
  db_username = "db_user"
  vpc_id = module.prod-network.id
  zones = local.prod_zones
  cidr_block = "10.100.200.0/23"
  multi_az = true
}

resource "aws_ecs_cluster" "prod-cluster" {
  name = "service-prod"
}

module "prod-api-server" {
  source = "./modules/service"
  env = "prod"
  name = "api-server"
  vpc_id = module.prod-network.id
  ecs_cluster_id = aws_ecs_cluster.prod-cluster.id
  subnet_ids = module.prod-network.private_subnet_ids
  lb_listener_arn = module.prod-network.lb_listener_arn
  lb_sg_id = module.prod-network.lb_sg_id
  lb_path_prefix = ["/api/", "/api/*"]
  lb_health_check_path = "/api/check"
  lb_priority = 1
  cpu = 1024
  memory = 2048
  port = 7777
  capacity_provider_strategy = [{
    capacity_provider = "FARGATE"
    base             = 1
    weight           = 1
  }, {
    capacity_provider = "FARGATE_SPOT"
    weight           = 4
  }]
  allow_ips = module.prod-network.nat_gw_ips  # NAT GW만 허용
}

resource aws_security_group_rule "api-server-to-rds-ingress-prod" {
  security_group_id = module.prod-rds.security_group.id
  type = "ingress"
  from_port = 5432
  to_port = 5432
  protocol = "tcp"
  source_security_group_id = module.prod-api-server.security_group.id
}

resource aws_security_group_rule "api-server-to-rds-egress-prod" {
  security_group_id = module.prod-api-server.security_group.id
  type = "egress"
  from_port = 5432
  to_port = 5432
  protocol = "tcp"
  source_security_group_id = module.prod-rds.security_group.id
}

module "prod-web-server" {
  source = "./modules/service"
  env = "prod"
  name = "web-server"
  vpc_id = module.prod-network.id
  ecs_cluster_id = aws_ecs_cluster.prod-cluster.id
  subnet_ids = module.prod-network.private_subnet_ids
  lb_listener_arn = module.prod-network.lb_listener_arn
  lb_sg_id = module.prod-network.lb_sg_id
  lb_path_prefix = ["/*"]
  lb_health_check_path = "/"
  lb_priority = 2
  cpu = 512  # 512 CPU units = 0.5 vCPU
  memory = 1024  # 1024 MiB
  port = 3000
  capacity_provider_strategy = [{
    capacity_provider = "FARGATE"
    base             = 1
    weight           = 1
  }, {
    capacity_provider = "FARGATE_SPOT"
    weight           = 4
  }]
}