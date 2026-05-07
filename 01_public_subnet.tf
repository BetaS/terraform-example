resource "aws_subnet" "public" {
  # TODO: var.zones 를 순회하며 public subnet을 생성

  tags = {
    Name = "${var.name}-subnet-public-${count.index}"
  }
}

resource "aws_route_table_association" "public" {
  # TODO: public 서브넷에 vpc default routing table을 연결
}