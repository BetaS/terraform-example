resource "aws_nat_gateway" "nat_gw" {
  count = length(var.zones) # NAT GW는 AZ 수 만큼 만들어줘야 고가용성이 유지 됨

  allocation_id = aws_eip.nat_gw[count.index].id  # 고정된 IP로 통신 할 수 있도록 EIP 할당 해줌
  subnet_id = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.name}-nat-gw-${count.index}"
  }
}

resource "aws_eip" "nat_gw" {
  count = length(var.zones)

  # NAT GW용 EIP 할당 하기 전에, 존재하는지 확인해서 삭제하고 새로만드는 역할
  # 실행할때마다 매번 새로붙이는 것은 아니고, 없으면 만드는 역할도 수행
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.name}-nat-eip-${count.index}"
  }
}

resource "aws_route" "private_nat_route" {
  count = length(var.zones)

  route_table_id              = aws_route_table.private_route_table[count.index].id
  destination_cidr_block      = "0.0.0.0/0"
  nat_gateway_id              = aws_nat_gateway.nat_gw[count.index].id
}