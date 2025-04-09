locals {
  lambda_runtime        = "python3.12"
  lambda_timeout        = 20
  lambda_memory_size    = 1024
  route53_id            = "Z00258873HV22349GRMON"
  domain_name           = "nknez.tech"
  api_domain_name       = "api.nknez.tech"
  dynamodb_billing_mode = "PAY_PER_REQUEST"
}