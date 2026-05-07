resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"  # AssumeRole 할 수 있도록 허용
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1" # GitHub OIDC의 루트 CA thumbprint
  ]
}

resource "aws_iam_role" "github_actions" {
  name = "github-actions-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            # TODO: 여기에 원하는 GitHub 저장소와 브랜치를 설정
            # 예: "repo:${repo 소유자 계정명}/${repo 이름}:ref:refs/heads/${branch name}"
            "token.actions.githubusercontent.com:sub" = [
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "github_actions" {
    name        = "github-actions-deploy-policy"
    description = "GitHub Actions Deploy Policy"

    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
        {
            Effect = "Allow",
            Action = [
              "ecs:UpdateService",
              "ecs:DescribeServices",
              "ecs:ListTasks",
              "ecs:DescribeTaskDefinition",
              "ecs:RegisterTaskDefinition",
              "ecr:GetAuthorizationToken",
              "ecr:BatchCheckLayerAvailability",
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchGetImage",
              "ecr:PutImage",
              "ecr:UploadLayerPart",
              "ecr:CompleteLayerUpload",
              "ecr:InitiateLayerUpload"
            ],
            Resource = "*"
        },
        {
          "Effect": "Allow",
          "Action": "iam:PassRole",
          "Resource": [
            # TODO: 앞서 생성한 역할들의 taskRole, taskExecutionRole ARN을 추가
          ]
        }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "github_actions_attach_policy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}