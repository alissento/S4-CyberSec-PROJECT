data "aws_iam_policy_document" "lambda_assume_role" { // Create a policy document for the Lambda function
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "lambda_policy" { // Create a policy for the Lambda function
  name = "lambda_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [ // Allow the Lambda function to access the DynamoDB tables
          "dynamodb:Scan",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ],
        "Effect" : "Allow",
        "Resource" : [
          aws_dynamodb_table.secdrive_user_files.arn,
          "${aws_dynamodb_table.secdrive_user_files.arn}/index/secdrive_user_id_index",
          aws_dynamodb_table.secdrive_users.arn,
        ]
      },
      {
        "Action" : [ // Allow the Lambda function to access S3 for pre-signed URLs
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        "Effect" : "Allow",
        "Resource" : "${aws_s3_bucket.s3_user_data.arn}/*"
      },
      {
        "Action" : [ // Allow the Lambda function to write logs
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:logs:*:*:*"
      },
      {
        "Action" : [ // Allow the Lambda function to use KMS for encryption/decryption
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ],
        "Effect" : "Allow",
        "Resource" : aws_kms_key.secdrive_encryption_key.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" { // Attach the policy to the role
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_role" "iam_for_lambda" { // Create a role for the Lambda function
  name               = "role_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_lambda_function" "store_user_data" { // Create the Lambda function for storing user data
  function_name = "store_user_data"
  handler       = "store_user_data.lambda_handler"
  runtime       = local.lambda_runtime
  memory_size   = local.lambda_memory_size
  timeout       = local.lambda_timeout
  role          = aws_iam_role.iam_for_lambda.arn
  filename      = "../backend/store_user_data.zip"
}

resource "aws_lambda_function" "get_user_data" { // Create the Lambda function for getting user data
  function_name = "get_user_data"
  handler       = "get_user_data.lambda_handler"
  runtime       = local.lambda_runtime
  memory_size   = local.lambda_memory_size
  timeout       = local.lambda_timeout
  role          = aws_iam_role.iam_for_lambda.arn
  filename      = "../backend/get_user_data.zip"
}

resource "aws_lambda_function" "generate_presigned_url" { // Create the Lambda function for generating pre-signed URLs
  function_name = "generate_presigned_url"
  handler       = "generate_presigned_url.lambda_handler"
  runtime       = local.lambda_runtime
  memory_size   = local.lambda_memory_size
  timeout       = local.lambda_timeout
  role          = aws_iam_role.iam_for_lambda.arn
  filename      = "../backend/generate_presigned_url.zip"
}

resource "aws_lambda_function" "confirm_upload" { // Create the Lambda function for confirming file upload
  function_name = "confirm_upload"
  handler       = "confirm_upload.lambda_handler"
  runtime       = local.lambda_runtime
  memory_size   = local.lambda_memory_size
  timeout       = local.lambda_timeout
  role          = aws_iam_role.iam_for_lambda.arn
  filename      = "../backend/confirm_upload.zip"
}

resource "aws_lambda_function" "get_user_profile" { // Create the Lambda function for getting user profile data
  function_name = "get_user_profile"
  handler       = "get_user_profile.lambda_handler"
  runtime       = local.lambda_runtime
  memory_size   = local.lambda_memory_size
  timeout       = local.lambda_timeout
  role          = aws_iam_role.iam_for_lambda.arn
  filename      = "../backend/get_user_profile.zip"
}

resource "aws_lambda_function" "generate_data_key" { // Create the Lambda function for generating data keys
  function_name = "generate_data_key"
  handler       = "generate_data_key.lambda_handler"
  runtime       = local.lambda_runtime
  memory_size   = local.lambda_memory_size
  timeout       = local.lambda_timeout
  role          = aws_iam_role.iam_for_lambda.arn
  filename      = "../backend/generate_data_key.zip"
}

resource "aws_lambda_function" "decrypt_data_key" { // Create the Lambda function for decrypting data keys
  function_name = "decrypt_data_key"
  handler       = "decrypt_data_key.lambda_handler"
  runtime       = local.lambda_runtime
  memory_size   = local.lambda_memory_size
  timeout       = local.lambda_timeout
  role          = aws_iam_role.iam_for_lambda.arn
  filename      = "../backend/decrypt_data_key.zip"
}

resource "aws_lambda_function" "delete_file" { // Create the Lambda function for deleting files
  function_name = "delete_file"
  handler       = "delete_file.lambda_handler"
  runtime       = local.lambda_runtime
  memory_size   = local.lambda_memory_size
  timeout       = local.lambda_timeout
  role          = aws_iam_role.iam_for_lambda.arn
  filename      = "../backend/delete_file.zip"
}