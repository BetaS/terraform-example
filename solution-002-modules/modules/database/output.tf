output "id" {
  value = aws_db_instance.rds.id
}

output "hostname" {
  value = aws_db_instance.rds.address
}

output "port" {
  value = aws_db_instance.rds.port
}

output "username" {
  value = aws_db_instance.rds.username
}

output "password" {
  value     = random_password.rds.result
  sensitive = true  # 비밀번호는 민감한 정보이므로 출력하지 않도록 설정
}

output "database" {
  value = aws_db_instance.rds.db_name
}

output "security_group" {
  value = aws_security_group.rds
}

output "subnet_ids" {
  value = aws_subnet.database[*].id
}