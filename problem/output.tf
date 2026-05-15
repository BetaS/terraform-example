output "vpc_id" {
  value = aws_vpc.main.id
}

output "web_env" {
  value = {
    actions_arn : aws_iam_role.github_actions.arn,
    ecr_name : aws_ecr_repository.web-server.name,
    ecs_cluster : aws_ecs_cluster.cluster.name,
    ecs_service : aws_ecs_service.web-server.name,
    container_name : "${var.name}-web-server",
    task_name : aws_ecs_task_definition.web-server.family
  }
}

output "api_env" {
  value = {
    actions_arn : aws_iam_role.github_actions.arn,
    ecr_name : aws_ecr_repository.api-server.name,
    ecs_cluster : aws_ecs_cluster.cluster.name,
    ecs_service : aws_ecs_service.api-server.name,
    container_name : "${var.name}-api-server",
    task_name : aws_ecs_task_definition.api-server.family
  }
}

output "cloudfront_url" {
  value = aws_cloudfront_distribution.main.domain_name
}