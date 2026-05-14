output "id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "lb_sg_id" {
  value = aws_security_group.alb.id
}

output "lb_listener_arn" {
  value = aws_lb_listener.main.arn
}

output "nat_gw_ips" {
  value = aws_nat_gateway.nat_gw[*].id
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.main.domain_name
  description = "001 output.tf의 cloudfront_url과 동일 용도"
}