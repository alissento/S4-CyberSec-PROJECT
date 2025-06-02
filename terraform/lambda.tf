resource "aws_lambda_function" "store_user_data" { // Create the Lambda function for storing user data
  function_name = "store_user_data"
  handler       = "store_user_data.lambda_handler"
  runtime       = local.lambda_runtime
  memory_size   = local.lambda_memory_size
  timeout       = local.lambda_timeout
  role          = aws_iam_role.store_user_data_role.arn
  filename      = "../backend/store_user_data.zip"
}

resource "aws_lambda_function" "get_user_data" { // Create the Lambda function for getting user data
  function_name = "get_user_data"
  handler       = "get_user_data.lambda_handler"
  runtime       = local.lambda_runtime
  memory_size   = local.lambda_memory_size
  timeout       = local.lambda_timeout
  role          = aws_iam_role.get_user_data_role.arn
  filename      = "../backend/get_user_data.zip"
}

resource "aws_lambda_function" "generate_presigned_url" { // Create the Lambda function for generating pre-signed URLs
  function_name = "generate_presigned_url"
  handler       = "generate_presigned_url.lambda_handler"
  runtime       = local.lambda_runtime
  memory_size   = local.lambda_memory_size
  timeout       = local.lambda_timeout
  role          = aws_iam_role.generate_presigned_url_role.arn
  filename      = "../backend/generate_presigned_url.zip"
}

resource "aws_lambda_function" "confirm_upload" { // Create the Lambda function for confirming file upload
  function_name = "confirm_upload"
  handler       = "confirm_upload.lambda_handler"
  runtime       = local.lambda_runtime
  memory_size   = local.lambda_memory_size
  timeout       = local.lambda_timeout
  role          = aws_iam_role.confirm_upload_role.arn
  filename      = "../backend/confirm_upload.zip"
}

resource "aws_lambda_function" "get_user_profile" { // Create the Lambda function for getting user profile data
  function_name = "get_user_profile"
  handler       = "get_user_profile.lambda_handler"
  runtime       = local.lambda_runtime
  memory_size   = local.lambda_memory_size
  timeout       = local.lambda_timeout
  role          = aws_iam_role.get_user_profile_role.arn
  filename      = "../backend/get_user_profile.zip"
}

resource "aws_lambda_function" "generate_data_key" { // Create the Lambda function for generating data keys
  function_name = "generate_data_key"
  handler       = "generate_data_key.lambda_handler"
  runtime       = local.lambda_runtime
  memory_size   = local.lambda_memory_size
  timeout       = local.lambda_timeout
  role          = aws_iam_role.generate_data_key_role.arn
  filename      = "../backend/generate_data_key.zip"
}

resource "aws_lambda_function" "decrypt_data_key" { // Create the Lambda function for decrypting data keys
  function_name = "decrypt_data_key"
  handler       = "decrypt_data_key.lambda_handler"
  runtime       = local.lambda_runtime
  memory_size   = local.lambda_memory_size
  timeout       = local.lambda_timeout
  role          = aws_iam_role.decrypt_data_key_role.arn
  filename      = "../backend/decrypt_data_key.zip"
}

resource "aws_lambda_function" "delete_file" { // Create the Lambda function for deleting files
  function_name = "delete_file"
  handler       = "delete_file.lambda_handler"
  runtime       = local.lambda_runtime
  memory_size   = local.lambda_memory_size
  timeout       = local.lambda_timeout
  role          = aws_iam_role.delete_file_role.arn
  filename      = "../backend/delete_file.zip"
}