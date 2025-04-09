output "website_url" { // Output of the URL of the website
  value = "https://${local.domain_name}"
}

output "raw_website_url" { // Output of the raw URL of the website
  value = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
}

output "http_api_url" { // Output the URL of the API Gateway
  value = "https://${local.api_domain_name}"
}

output "raw_http_api_url" { // Output the raw URL of the API Gateway
  value = aws_apigatewayv2_api.api_gw_secdrive.api_endpoint
}

output "cloudfront_distribution_id" { // Output the ID of the CloudFront distribution
  value = aws_cloudfront_distribution.s3_distribution.id
}