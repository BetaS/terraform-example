variable "name" {
  type = string
  description = "생성할 리소스 이름"
  default = "example"
}

variable "public_cidr" {
  type = string
  description = "VPC CIDR 블록"
  default = "10.100.0.0/16"
}

variable "private_cidr" {
  type = string
  description = "ECS CIDR 블록"
  default = "10.101.0.0/16"
}

variable "db_cidr" {
  type = string
  description = "DB CIDR 블록"
  default = "10.102.0.0/16"
}

variable "zones" {
  type = list(string)
  description = "생성할 리전 리스트"
  default = ["ap-northeast-2a", "ap-northeast-2c"]
}