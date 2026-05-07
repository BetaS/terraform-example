# 만약 AZ 1개만 지정하는 경우에는 ALB의 HA(고가용성) 정책으로 인해서 리소스 생성이 안됩니다.
resource "aws_subnet" "default" {
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 0)
  # 10.200.0.0/16 -> VPC cidr
  ## 8개의 newbits 할당 한다면? -> 10.200.0.0/24 = 16+8=24
  ## 2^8 = 256개의 서브넷을 만들 수 있다.
  ## ex: cidrsubnet(var.vpc_cidr, 8, 3) -> 10.200.3.0/24

  availability_zone = "ap-northeast-2d"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}-subnet-default"
  }
}

resource "aws_route_table_association" "default" {
  subnet_id = aws_subnet.default.id
  route_table_id = aws_vpc.main.main_route_table_id
}

resource "aws_subnet" "public" {
  count = length(var.zones)  # parameter로 AZ리스트를 받아서, 전체의 리스트 길이를 반환
  # 접근 할때는 aws_subnet.public[0].id, aws_subnet.public[1].id
  # for문으로 생각하면 for(i in range(0, length(var.zones))) 의 i 값은 count.index에 대응됩니다.

  vpc_id = aws_vpc.main.id
  # 이미 default 서브넷에서 0번째 인덱스를 사용했기 때문에 +1을 수행 함
  # vpc_cidr = 10.0.0.0/8 이라고 가정
  # 두번째 파라미터는 newbits의 갯수, 만약 2를 입력 10.0.0.0/10 으로 변경된다는 의미-> 2의 2승이니깐 총 4개의 새로운 네트워크를 만들 수 있다.
  # 세번째 파라미터는 4개의 새로운 네트워크 중 몇번째 를 가져올거냐는 의미로 사용
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index+1)  # 256개의 서브넷을 만들 수 있는데, 만약 var.zones의 크기가 256을 초과하면?? 당연히 에러가 발생
  # element 함수는 리스트에서 특정 인덱스의 값을 가져오는 함수입니다.
  # var.zones[0] vs element(var.zones, 0)
  # 후자가 더 안전한 방법입니다. null-safe
  availability_zone = element(var.zones, count.index)  # var.zones[count.index]와 동일한 기능
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}-subnet-public-${count.index}"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.zones)
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_vpc.main.main_route_table_id
}

resource "aws_subnet" "private" {
  count = length(var.zones)
  vpc_id = aws_vpc.main.id
  # ceil(log(length(var.zones), 2))
  # ceil = math.ceil -> 올림함수
  # log = math.log -> 로그함수 log2
  # 10개의 zone 걸쳐서 배포 하는 경우에 -> newbit를 몇개 할당 해야할까?
  # 2^n >= 10 = 2의 4승은 16개까지 만들수 있다.
  # cidr_block = cidrsubnet(var.private_cidr, ceil(log(length(var.zones), 2)), count.index)
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index + length(var.zones) + 1)
  availability_zone = element(var.zones, count.index)

  # private 서브넷은 절대 public ip 할당이 자동화 되어있으면 안됨
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.name}-subnet-private-${count.index}"
  }
}

# private 서브넷은 default route table 을 사용하면
# igw 에 붙기 때문에 자유로운 외부 통신이 가능하다는 문제가 있음
# 따라서, private 서브넷은 route table을 따로 만들어서 관리를 개별적으로 해주는게 좋음.
resource "aws_route_table" "private_route_table" {
  count = length(var.zones)  # private 서브넷 갯수만큼 라우팅 테이블을 만들어서 관리
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-route-table-private-${count.index}"
  }
}

resource "aws_route_table_association" "route_table_association_private" {
  count = length(var.zones)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}
