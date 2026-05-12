locals {
  dev_vpc_cidr = "10.200.0.0/16"
  dev_private_cidr = "10.200.100.0/24"
  dev_zones = ["ap-northeast-2a"]
}

module "dev-network" {
  source    = "./modules/network"
  name      = "dev"
  vpc_cidr  = local.dev_vpc_cidr
  private_cidr = local.dev_private_cidr
  zones     = local.dev_zones
  providers = {
    aws.global = aws.global
  }
}

module "dev-rds" {
  source = "./modules/database"
  name   = "service-dev"
  db_username = "db_user"
  vpc_id = module.dev-network.id
  zones = ["ap-northeast-2a", "ap-northeast-2c"]
  cidr_block = "10.200.200.0/23"
  multi_az = false
}

resource "aws_ecs_cluster" "dev-cluster" {
  name = "service-dev"
}

module "dev-web-server" {
  env = "dev"
  source = "./modules/service"
  name = "web-server"
  vpc_id = module.dev-network.id
  ecs_cluster_id = aws_ecs_cluster.dev-cluster.id
  subnet_ids = module.dev-network.private_subnet_ids
  lb_listener_arn = module.dev-network.lb_listener_arn
  lb_sg_id = module.dev-network.lb_sg_id
  lb_path_prefix = ["/*"]
  lb_health_check_path = "/"
  lb_priority = 2
  cpu = 256  # 256 CPU units = 0.25 vCPU
  memory = 512  # 512 MiB
  port = 3000
  capacity_provider_strategy = [{
    capacity_provider = "FARGATE_SPOT"
    weight           = 1
  }]
}

module "dev-api-server" {
  env = "dev"
  source = "./modules/service"
  name = "api-server"
  vpc_id = module.dev-network.id
  ecs_cluster_id = aws_ecs_cluster.dev-cluster.id
  subnet_ids = module.dev-network.private_subnet_ids
  lb_listener_arn = module.dev-network.lb_listener_arn
  lb_sg_id = module.dev-network.lb_sg_id
  lb_path_prefix = ["/api/", "/api/*"]
  lb_priority = 1
  lb_health_check_path = "/api/check"
  cpu = 512
  memory = 1024
  port = 7777
  capacity_provider_strategy = [{
    capacity_provider = "FARGATE_SPOT"
    weight           = 1
  }]
  allow_ips = module.dev-network.nat_gw_ips  # NAT GW만 허용
}

resource aws_security_group_rule "api-server-to-rds-ingress-dev" {
  security_group_id = module.dev-rds.security_group.id
  type = "ingress"
  from_port = 5432
  to_port = 5432
  protocol = "tcp"
  source_security_group_id = module.dev-api-server.security_group.id
}

resource aws_security_group_rule "api-server-to-rds-egress-dev" {
  security_group_id = module.dev-api-server.security_group.id
  type = "egress"
  from_port = 5432
  to_port = 5432
  protocol = "tcp"
  source_security_group_id = module.dev-rds.security_group.id
}