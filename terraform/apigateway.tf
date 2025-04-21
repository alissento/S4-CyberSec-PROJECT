// This file is used to create the API Gateway for the project
resource "aws_apigatewayv2_api" "api_gw_secdrive" { // Create an API Gateway
  name          = "api-gateway-secdrive"            // The name of the API Gateway
  protocol_type = "HTTP"                            // The protocol used by the API Gateway

  cors_configuration {
    allow_origins = ["*"] // Allow the origin of the request
    allow_methods = ["GET", "OPTIONS", "POST"]
    allow_headers = ["*"]
  }

  depends_on = [aws_s3_bucket_website_configuration.website_s3b]
}

resource "aws_acm_certificate" "tls_cert_api" { // Create a certificate for the API Gateway
  domain_name       = local.api_domain_name
  validation_method = "DNS"

  tags = {
    Name = "api.nknez.tech certificate"
  }
}

resource "aws_route53_record" "tls_cert_api_validation_cname" {
  for_each = {
    for dvo in aws_acm_certificate.tls_cert_api.domain_validation_options :
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

  depends_on = [aws_acm_certificate.tls_cert_api]
}

resource "aws_acm_certificate_validation" "tls_cert_api_validation" {
  certificate_arn         = aws_acm_certificate.tls_cert_api.arn
  validation_record_fqdns = [for record in aws_route53_record.tls_cert_api_validation_cname : record.fqdn]

  depends_on = [aws_acm_certificate.tls_cert_api]
}

resource "aws_apigatewayv2_domain_name" "custom_domain_api_gw" {
  domain_name = local.api_domain_name
  domain_name_configuration {
    certificate_arn = aws_acm_certificate.tls_cert_api.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  depends_on = [aws_acm_certificate_validation.tls_cert_api_validation]
}

resource "aws_apigatewayv2_api_mapping" "api_mapping" {
  api_id      = aws_apigatewayv2_api.api_gw_secdrive.id
  domain_name = aws_apigatewayv2_domain_name.custom_domain_api_gw.domain_name
  stage       = aws_apigatewayv2_stage.default_stage.name

  depends_on = [aws_acm_certificate_validation.tls_cert_api_validation]
}

resource "aws_route53_record" "custom_domain_api_gw_record" {
  zone_id = local.route53_id
  name    = aws_apigatewayv2_domain_name.custom_domain_api_gw.domain_name
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.custom_domain_api_gw.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.custom_domain_api_gw.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# resource "aws_apigatewayv2_integration" "load_products_integration" { // Create an integration for the kits listing
#   api_id           = aws_apigatewayv2_api.api_gw_secdrive.id
#   integration_type = "AWS_PROXY"
#   integration_uri  = aws_lambda_function.list_products.invoke_arn
# }

# resource "aws_apigatewayv2_route" "route_products" { // Create a route for the product listing
#   api_id    = aws_apigatewayv2_api.api_gw_secdrive.id
#   route_key = "GET /loadProducts"
#   target    = "integrations/${aws_apigatewayv2_integration.load_products_integration.id}"
# }

# resource "aws_lambda_permission" "products_api_gateway_permission" { // Create a permission for the kits listing
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.list_products.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_apigatewayv2_api.api_gw_secdrive.execution_arn}/*"
# }

resource "aws_apigatewayv2_stage" "default_stage" { // Create a stage for the API Gateway
  api_id      = aws_apigatewayv2_api.api_gw_secdrive.id
  name        = "$default"
  auto_deploy = true
}