variable "name" {
  type = string
  description = "환경의 이름"
}

variable "vpc_cidr" {
  type = string
  description = "VPC에서 사용할 CIDR 블록입니다."
}

variable "private_cidr" {
  type = string
  description = "private subnet에서 사용할 CIDR 블록입니다."
}

variable "zones" {
  type = list(string)
  description = "VPC에서 사용할 가용 영역입니다."
}
