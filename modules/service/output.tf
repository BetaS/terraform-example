output "security_group" {
  value = aws_security_group.service
}

output "task_role" {
  value = aws_iam_role.task_role
}