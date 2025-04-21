# --- Cognito User Pool ---
resource "aws_cognito_user_pool" "secdrive_user_pool" {
  name             = "secdrive_user_pool"
  alias_attributes = ["email"]
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  auto_verified_attributes = ["email"] # Verify email automatically
}


resource "aws_cognito_user_pool_domain" "secdrive_user_pool_domain" {
  domain       = "secdrive-auth-nk"
  user_pool_id = aws_cognito_user_pool.secdrive_user_pool.id
}

resource "aws_cognito_user_pool_client" "app_client" {
  name         = "secdrive-web-client"
  user_pool_id = aws_cognito_user_pool.secdrive_user_pool.id

  generate_secret = false

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]           # 'code' is preferred (Authorization Code Grant)
  allowed_oauth_scopes                 = ["openid", "email", "profile"] # Standard scopes

  callback_urls = ["https://nknez.tech/callback"]
  logout_urls   = ["https://nknez.tech/logout"]

  supported_identity_providers = ["COGNITO"]

  prevent_user_existence_errors = "ENABLED"
}