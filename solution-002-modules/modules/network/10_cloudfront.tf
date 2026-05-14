resource "aws_cloudfront_distribution" "main" {
  provider = aws.global
  origin {
    # Cloudfront가 ALB를 오리진으로 사용하도록 설정 -> alb의 dns_name을 사용
    domain_name = aws_lb.main.dns_name
    origin_id   = "internalALB"

    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port              = 80
      https_port             = 443
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  # 200 class -> 100, 200, 300 3가지가 존재
  # 100 class -> 미국, 유럽 -> 제일 쌈, 한국에서 테스트할때 쪼금 느리다는 문제, 개발 환경 100
  # 200 class -> 미국, 유럽, 아시아 (한국 포함), 가장 밸런스 좋은 형태, 운영 환경에서는 200
  # 300 class -> 미국, 유럽, 아시아, 남미, 아프리카 -> 제일 비쌈
  price_class  = "PriceClass_200"
  http_version = "http2"

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "internalALB"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "internalALB"
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "${var.name}-cloudfront"
  }
}
