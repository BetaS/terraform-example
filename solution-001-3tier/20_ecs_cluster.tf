resource "aws_ecs_cluster" "cluster" {
  name = var.name
}

# Fargate가 이미지 pull, CloudWatch Logs 전송 등에 사용하는 역할
resource "aws_iam_role" "execution_role" {
  name = "ecsTaskExecutionRole-${var.name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "execution_role" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
