resource "aws_subnet" "database" {
  count = length(var.zones)
  vpc_id = var.vpc_id
  cidr_block = cidrsubnet(var.cidr_block, ceil(log(length(var.zones), 2)), count.index)
  availability_zone = element(var.zones, count.index)
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.name}-subnet-private-db-${count.index}"
  }
}

resource "aws_route_table" "database_route_table" {
  count = length(var.zones)
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.name}-subnet-private-db-route-table-${count.index}"
  }
}
# DB서브넷은 외부로 연결할 필요가 없기 때문에 NAT GW 를 붙이지 않습니다.

resource "aws_route_table_association" "database" {
  count = length(var.zones)
  subnet_id = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database_route_table[count.index].id
}