output "security_group" {
  value = aws_security_group.service
}

output "task_role" {
  value = aws_iam_role.task_role
}

output "ecr_name" {
  value = aws_ecr_repository.service.name
}

output "ecs_service_name" {
  value = aws_ecs_service.service.name
}

output "task_family" {
  value = aws_ecs_task_definition.service.family
}

output "container_name" {
  value       = var.name
  description = "태스크 정의·ALB의 container_name과 동일"
}