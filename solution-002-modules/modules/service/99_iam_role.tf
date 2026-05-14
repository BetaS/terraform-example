resource "aws_iam_role" "task_role" {
  name = "ecsTaskRole-${var.env}-${var.name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "ecs-tasks.amazonaws.com"
          ]
        }
      }
    ]
  })
}

# Task execution 권한은 execution_role(루트에서 생성·전달)에 두고, task_role은 앱 전용(예: Secrets 읽기)만 부여
resource "aws_iam_role_policy" "task_rds_secret" {
  count = var.rds_secret_arn != "" ? 1 : 0
  name  = "ecsTaskRole-${var.env}-${var.name}-rds-secret"
  role  = aws_iam_role.task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.rds_secret_arn
      }
    ]
  })
}
