resource "aws_nat_gateway" "nat_gw" {
  # TODO: var.zones 를 순회하며 NAT GW를 생성
  # NAT GW는 AZ 수 만큼 만들어줘야 고가용성이 유지 됨
  count = length(var.zones)

  allocation_id = aws_eip.nat_gw[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.name}-nat-gw-${count.index}"
  }
}

resource "aws_eip" "nat_gw" {
  # NAT GW 갯수 만큼 EIP 할당
  count = length(var.zones)

  # EIP를 재정의 하게 될 때 기존것을 삭제하고 만드는것이 아닌, 만들고 기존것을 삭제 (graceful delete)
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.name}-nat-eip-${count.index}"
  }
}