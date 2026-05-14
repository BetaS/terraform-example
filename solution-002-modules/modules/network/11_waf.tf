resource "aws_wafv2_web_acl" "main" {
  provider = aws.global
  name     = "${var.name}-waf"
  scope    = "CLOUDFRONT" # 소스를 Cloudfront로 지정
  # REGIONAL 도 있는데
  # REGIONAL은 ALB로 바로 붙이는 경우에 WAF의 scope을 REGIONAL로 설정

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "cloudfrontWAF"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 10

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "allow_ips"
    priority = 1
    action {
      allow {}
    }
    statement {
      ip_set_reference_statement {
        # CloudFront를 통해서 접근하는 경우에만 WAF에서 허용
        arn = aws_wafv2_ip_set.cloudfront_prefix_list.arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "allow_ips"
      sampled_requests_enabled   = true
    }
  }

  tags = {
    Name = "${var.name}-waf"
  }
}

data "aws_ip_ranges" "cloudfront" {
  services = ["CLOUDFRONT"]
  regions  = ["global"] # CloudFront는 global 서비스임
}

# Cloudfront의 IP Prefix List를 가져와 IPset 지정을 해줍니다.
resource "aws_wafv2_ip_set" "cloudfront_prefix_list" {
  provider           = aws.global
  name               = "${var.name}-cloudfront-prefix-list"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  description        = "CloudFront IPs"

  addresses = data.aws_ip_ranges.cloudfront.cidr_blocks # CF의 IP를 Origin 으로 하는 경우에만 승인 (직접 접근 방지)

  tags = {
    Name = "${var.name}-cloudfront-prefix-list"
  }
}