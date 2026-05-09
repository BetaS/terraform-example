resource "aws_db_instance" "rds" {
  identifier           = "${var.name}-rds"
  engine               = "postgres"
  instance_class       = "db.t3.medium"
  allocated_storage    = 20
  db_name              = "${var.name}_db"
  username             = "${var.name}_user"
  password             = random_password.rds.result
  multi_az             = length(var.zones) > 1
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

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