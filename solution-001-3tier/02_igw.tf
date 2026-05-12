resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-igw"
  }
}

resource "aws_route" "internet_access" {
  # TODO: internet gateway에 모든 트래픽을 허용하는 route를 추가
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0" # internet
  gateway_id             = aws_internet_gateway.main.id
}