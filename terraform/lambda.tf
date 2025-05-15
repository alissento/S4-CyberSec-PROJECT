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
        "Action" : [ // Allow the Lambda function to write logs
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:logs:*:*:*"
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