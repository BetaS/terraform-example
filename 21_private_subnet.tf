resource "aws_subnet" "private" {
  # TODO: var.zones 를 순회하며 private subnet을 생성
  count = length(var.zones)

  vpc_id = aws_vpc.main.id

  cidr_block = cidrsubnet(var.vpc_cidr, 8, length(var.zones) + count.index)
  availability_zone = var.zones[count.index]

  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-subnet-private-${count.index}"
  }
}

# private 서브넷은 default route table 을 사용하면 igw 에 붙기 때문에 자유로운 외부 통신이 가능하다는 문제가 있음
# 따라서, private 서브넷은 route table을 따로 만들어서 관리를 개별적으로 해주는게 좋음.
resource "aws_route_table" "private_route_table" {
  # TODO: private 서브넷 갯수만큼 라우팅 테이블을 만들어서 관리
  count = length(var.zones)
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-route-table-private-${count.index}"
  }
}

resource "aws_route_table_association" "route_table_association_private" {
  # TODO: private 서브넷에 private route table을 연결
  count = length(var.zones)
  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}

resource "aws_route" "private_nat_route" {
  # TODO: private 서브넷에 NAT GW로의 모든 트래픽(0.0.0.0/0)을 허용하는 route를 추가
  count = length(var.zones)
  route_table_id = aws_route_table.private_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
}