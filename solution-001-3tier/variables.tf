variable "name" {
  type        = string
  description = "생성할 리소스 이름"
  default     = "example"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR 블록"
  default     = "10.100.0.0/16"
}

variable "zones" {
  type        = list(string)
  description = "생성할 리전 리스트"
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}