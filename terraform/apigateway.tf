// This file is used to create the API Gateway for the project
resource "aws_apigatewayv2_api" "api_gw_secdrive" { // Create an API Gateway
  name          = "api-gateway-secdrive"            // The name of the API Gateway
  protocol_type = "HTTP"                            // The protocol used by the API Gateway

  cors_configuration {
    allow_origins = ["http://localhost:5174", "http://localhost:5173", "https://nknez.tech", "*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key", "X-Amz-Security-Token", "X-Amz-User-Agent"]
    expose_headers = ["ETag"]
    max_age = 86400
    allow_credentials = false
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

resource "aws_apigatewayv2_integration" "store_user_data_integration" { // Create an integration for the kits listing
  api_id           = aws_apigatewayv2_api.api_gw_secdrive.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.store_user_data.invoke_arn
}

resource "aws_apigatewayv2_integration" "get_user_data_integration" { // Create an integration for the kits listing
  api_id           = aws_apigatewayv2_api.api_gw_secdrive.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.get_user_data.invoke_arn
}

resource "aws_apigatewayv2_integration" "generate_presigned_url_integration" { // Create an integration for generating pre-signed URLs
  api_id           = aws_apigatewayv2_api.api_gw_secdrive.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.generate_presigned_url.invoke_arn
}

resource "aws_apigatewayv2_integration" "confirm_upload_integration" { // Create an integration for confirming file upload
  api_id           = aws_apigatewayv2_api.api_gw_secdrive.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.confirm_upload.invoke_arn
}

resource "aws_apigatewayv2_integration" "get_user_profile_integration" { // Create an integration for getting user profile data
  api_id           = aws_apigatewayv2_api.api_gw_secdrive.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.get_user_profile.invoke_arn
}

resource "aws_apigatewayv2_integration" "generate_data_key_integration" { // Create an integration for generating data keys
  api_id           = aws_apigatewayv2_api.api_gw_secdrive.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.generate_data_key.invoke_arn
}

resource "aws_apigatewayv2_integration" "decrypt_data_key_integration" { // Create an integration for decrypting data keys
  api_id           = aws_apigatewayv2_api.api_gw_secdrive.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.decrypt_data_key.invoke_arn
}
resource "aws_apigatewayv2_route" "route_store_user_data" {
  api_id    = aws_apigatewayv2_api.api_gw_secdrive.id
  route_key = "POST /storeUserData"
  target    = "integrations/${aws_apigatewayv2_integration.store_user_data_integration.id}"
}

resource "aws_apigatewayv2_route" "route_get_user_data" { 
  api_id    = aws_apigatewayv2_api.api_gw_secdrive.id
  route_key = "GET /getUserData"
  target    = "integrations/${aws_apigatewayv2_integration.get_user_data_integration.id}"
}

resource "aws_apigatewayv2_route" "route_generate_presigned_url" {
  api_id    = aws_apigatewayv2_api.api_gw_secdrive.id
  route_key = "POST /generatePresignedUrl"
  target    = "integrations/${aws_apigatewayv2_integration.generate_presigned_url_integration.id}"
}

resource "aws_apigatewayv2_route" "route_confirm_upload" {
  api_id    = aws_apigatewayv2_api.api_gw_secdrive.id
  route_key = "POST /confirmUpload"
  target    = "integrations/${aws_apigatewayv2_integration.confirm_upload_integration.id}"
}

resource "aws_apigatewayv2_route" "route_get_user_profile" {
  api_id    = aws_apigatewayv2_api.api_gw_secdrive.id
  route_key = "GET /getUserProfile"
  target    = "integrations/${aws_apigatewayv2_integration.get_user_profile_integration.id}"
}

resource "aws_apigatewayv2_route" "route_generate_data_key" {
  api_id    = aws_apigatewayv2_api.api_gw_secdrive.id
  route_key = "POST /generateDataKey"
  target    = "integrations/${aws_apigatewayv2_integration.generate_data_key_integration.id}"
}

resource "aws_apigatewayv2_route" "route_decrypt_data_key" {
  api_id    = aws_apigatewayv2_api.api_gw_secdrive.id
  route_key = "POST /decryptDataKey"
  target    = "integrations/${aws_apigatewayv2_integration.decrypt_data_key_integration.id}"
}

resource "aws_lambda_permission" "store_user_data_api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.store_user_data.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_gw_secdrive.execution_arn}/*"
}

resource "aws_lambda_permission" "get_user_data_api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_user_data.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_gw_secdrive.execution_arn}/*"
}

resource "aws_lambda_permission" "generate_presigned_url_api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_presigned_url.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_gw_secdrive.execution_arn}/*"
}

resource "aws_lambda_permission" "confirm_upload_api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.confirm_upload.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_gw_secdrive.execution_arn}/*"
}

resource "aws_lambda_permission" "get_user_profile_api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_user_profile.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_gw_secdrive.execution_arn}/*"
}

resource "aws_lambda_permission" "generate_data_key_api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_data_key.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_gw_secdrive.execution_arn}/*"
}

resource "aws_lambda_permission" "decrypt_data_key_api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.decrypt_data_key.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_gw_secdrive.execution_arn}/*"
}

resource "aws_apigatewayv2_stage" "default_stage" { // Create a stage for the API Gateway
  api_id      = aws_apigatewayv2_api.api_gw_secdrive.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_rate_limit  = 100
    throttling_burst_limit = 200
  }
}