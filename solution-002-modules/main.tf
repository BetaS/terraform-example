terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 기본 aws 프로바이더에서는 ap-northeast-2 리전의 리소스를 생성함 -> 서울 리전
provider "aws" {
  region = "ap-northeast-2"
  profile = "sandbox"  # 실제 환경에서는 맞는 CLI Profile 설정 필요함, IAM Roles Anywhere 같은거 쓰면 됨
}

# Cloudfront 쓰기 위해 글로벌 리전 하나 설정
provider "aws" {
  alias  = "global"
  region = "us-east-1"
  profile = "sandbox"
}