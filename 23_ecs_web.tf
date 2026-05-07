locals {
  web_port = 3000
}

# TODO: API 서비스를 복제해서 생성
# 주의사항 : 복제한 서비스에서 api-server를 web-server 로 이름, resource identifier 잘 변경해 줄 것
# 주의사항 : RDS로의 트래픽은 허용하지 말 것