# DB 패스워드를 랜덤으로 생성하기 위한 리소스를 정의
resource "random_password" "rds" {
  length           = 16
  special          = true
  upper            = true
  lower            = true
  numeric          = true
  min_upper        = 1
  min_special      = 1
  min_numeric      = 1
  override_special = "!#$&*()-=+[]{}<>:?"
}

# 어플리케이션에서 실제로 접속이 가능하게끔 secrets manager를 통해서 DB권한을 주입하는 대표적인 방법
# ParameterStore (SSM) 도 써도 되는데, 평문으로 저장되니 털리면 다 털림
resource "aws_secretsmanager_secret" "rds" {
  name        = "${var.name}-rds"
  description = "RDS connection info for ${var.name}"
  recovery_window_in_days = 0
  tags = {
    Name = "${var.name}-rds"
  }
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id = aws_secretsmanager_secret.rds.id
  secret_string = jsonencode({
    engine   = "postgres"
    host     = aws_db_instance.rds.address
    port     = aws_db_instance.rds.port
    username = aws_db_instance.rds.username
    password = random_password.rds.result
    database = aws_db_instance.rds.db_name
  })
}


resource "aws_iam_role_policy" "task_role_api_rds_secret" {
  name = "ecsTaskRole-${var.name}-api-rds-secret"
  role = aws_iam_role.task_role_api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.rds.arn
      }
    ]
  })
}
