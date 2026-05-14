variable "name" {
  type        = string
  description = "환경의 이름"
}

variable "vpc_id" {
  type        = string
  description = "생성할 VPC ID 입니다."
}

variable "cidr_block" {
  type        = string
  description = "DB 서브넷의 CIDR 블록입니다."
}

variable "zones" {
  type        = list(string)
  description = "VPC에서 사용할 가용 영역입니다."
}

variable "db_username" {
  type        = string
  description = "DB 사용자 이름입니다."
  default     = "db_user"
}

variable "db_name" {
  type        = string
  description = "DB 이름입니다."
  default     = "mydb"
}

variable "multi_az" {
  type        = bool
  description = "Multi-AZ 배포 여부입니다."
  default     = false
}