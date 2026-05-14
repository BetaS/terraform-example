variable "execution_role_arn" {
  type        = string
  description = "ECS task execution role ARN (ECR pull, CloudWatch Logs 등). 환경 루트에서 생성한 역할을 공유"
}

variable "env" {
  type        = string
  description = "환경 이름"
}

variable "name" {
  type        = string
  description = "서비스 이름"
}

variable "ecs_cluster_id" {
  type        = string
  description = "ECS 클러스터 ID입니다."
}

variable "subnet_ids" {
  type        = list(string)
  description = "서브넷 ID 목록입니다."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID입니다."
}

variable "cpu" {
  type        = number
  description = "vCPU 리소스입니다."
  default     = 256
}

variable "memory" {
  type        = number
  description = "vRAM 리소스입니다."
  default     = 512
}

variable "port" {
  type        = number
  description = "DB 사용자 이름입니다."
  default     = 3000
}

variable "lb_listener_arn" {
  type        = string
  description = "ALB 리스너 리소스"
}

variable "lb_sg_id" {
  type        = string
  description = "ALB SG 리소스"
}

variable "lb_path_prefix" {
  type        = list(string)
  description = "ALB Path 패턴"
}

variable "capacity_provider_strategy" {
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = optional(number)
  }))
  description = "ECS 용량 공급자 전략"
  default = [{
    capacity_provider = "FARGATE"
    base              = 1
    weight            = 1
    }, {
    capacity_provider = "FARGATE_SPOT"
    weight            = 4
  }]
}

variable "allow_ips" {
  type        = list(string)
  description = "SG에서 허용할 IP & CIDR 목록들"
  default     = []
}

variable "lb_priority" {
  type        = number
  description = "ALB 리스너 우선순위"
}

variable "lb_health_check_path" {
  type        = string
  description = "ALB 헬스체크 경로"
  default     = "/"
}

variable "rds_secret_arn" {
  type        = string
  description = "RDS Secrets Manager ARN. API만 설정. 비어 있으면 IAM 시크릿 정책·컨테이너 env·RDS SG egress 없음(웹 등)"
  default     = ""
}

variable "rds_security_group_id" {
  type        = string
  description = "RDS 보안 그룹 ID. rds_secret_arn과 함께 API만 설정. 웹은 비워 두어 RDS로의 5432 egress 자체가 없어야 함"
  default     = ""
}