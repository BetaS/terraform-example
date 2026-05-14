resource "aws_db_instance" "rds" {
  identifier             = "${var.name}-rds"
  engine                 = "postgres"
  instance_class         = "db.t3.medium"
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.rds.result # 패스워드는 랜덤으로 생성된 값을 사용
  multi_az               = var.multi_az
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  skip_final_snapshot    = true

  tags = {
    Name = "${var.name}-rds"
  }

  lifecycle {
    ignore_changes = [
      password, # 패스워드 변경은 RDS 인스턴스가 삭제될 때만 진행
    ]
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.name}-rds-subnet-group"
  subnet_ids = aws_subnet.database[*].id
  tags = {
    Name = "${var.name}-rds-subnet-group"
  }
}