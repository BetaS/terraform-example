resource "aws_subnet" "public" {
  count = length(var.zones)  # parameter로 AZ리스트를 받아서, 전체의 리스트 길이를 반환
  # 접근 할때는 aws_subnet.public[0].id, aws_subnet.public[1].id
  # for문으로 생각하면 for(i in range(0, length(var.zones))) 의 i 값은 count.index에 대응됩니다.

  vpc_id = aws_vpc.main.id
  # 이미 default 서브넷에서 0번째 인덱스를 사용했기 때문에 +1을 수행 함
  # vpc_cidr = 10.0.0.0/8 이라고 가정
  # 두번째 파라미터는 newbits의 갯수, 만약 2를 입력 10.0.0.0/10 으로 변경된다는 의미-> 2의 2승이니깐 총 4개의 새로운 네트워크를 만들 수 있다.
  # 세번째 파라미터는 4개의 새로운 네트워크 중 몇번째 를 가져올거냐는 의미로 사용
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)  # 256개의 서브넷을 만들 수 있는데, 만약 var.zones의 크기가 256을 초과하면?? 당연히 에러가 발생
  # element 함수는 리스트에서 특정 인덱스의 값을 가져오는 함수입니다.
  # var.zones[0] vs element(var.zones, 0)
  # 후자가 더 안전한 방법입니다. null-safe
  availability_zone = var.zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}-subnet-public-${count.index}"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.zones)
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_vpc.main.default_route_table_id
}