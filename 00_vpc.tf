resource "aws_vpc" "main" {
  cidr_block            = # TODO: CIDR 변수에서 불러오기
  enable_dns_hostnames  = true
  enable_dns_support    = true
  tags = {
    Name = "${var.name}-vpc"
  }
}