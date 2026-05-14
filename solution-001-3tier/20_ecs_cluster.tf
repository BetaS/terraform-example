resource "aws_ecs_cluster" "cluster" {
  name = var.name
}

# Fargate가 이미지 pull, CloudWatch Logs 전송 등에 사용하는 역할
resource "aws_iam_role" "execution_role" {
  name = "ecsTaskExecutionRole-${var.name}"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

resource "aws_iam_role_policy_attachment" "execution_role" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
