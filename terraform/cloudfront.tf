resource "aws_cloudfront_distribution" "s3_distribution" { // Define the CloudFront distribution for the S3 bucket
  provider = aws.us-east-1                                 // Use the alias AWS provider for the us-east-1 region 

  aliases = [local.domain_name] // Define the domain name for the CloudFront distribution 

  origin { // Define the origin for the CloudFront distribution 
    domain_name = "nknez.tech.s3-website.eu-central-1.amazonaws.com"
    origin_id   = "S3-Website-nknez.tech"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = false
  comment             = "S3 bucket website distribution"
  default_root_object = "index.html"

  default_cache_behavior { // Define the default cache behavior for the CloudFront distribution 
    target_origin_id       = "S3-Website-nknez.tech"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  # Custom error page for SPA routing
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions { // Define the restrictions for the CloudFront distribution 
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate { // Define the viewer certificate for the CloudFront distribution 
    acm_certificate_arn      = aws_acm_certificate.tls-cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  depends_on = [aws_acm_certificate_validation.tls_cert_validation]
}

resource "aws_acm_certificate" "tls-cert" { // Define the ACM certificate for the CloudFront distribution 
  provider = aws.us-east-1

  domain_name       = local.domain_name
  validation_method = "DNS"

  tags = {
    Name = "nknez.tech certificate"
  }
}

resource "aws_route53_record" "tls_cert_validation_cname" {
  provider = aws.us-east-1

  for_each = {
    for dvo in aws_acm_certificate.tls-cert.domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = local.route53_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.value]

  depends_on = [aws_acm_certificate.tls-cert]
}

resource "aws_acm_certificate_validation" "tls_cert_validation" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.tls-cert.arn
  validation_record_fqdns = [for record in aws_route53_record.tls_cert_validation_cname : record.fqdn]

  depends_on = [aws_acm_certificate.tls-cert]
}

resource "aws_route53_record" "record_for_cloudfront" { // Define the Route 53 record for the CloudFront distribution
  zone_id = local.route53_id
  name    = local.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}