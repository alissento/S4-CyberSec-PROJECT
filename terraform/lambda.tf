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