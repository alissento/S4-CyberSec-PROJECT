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

// Base logging policy for all Lambda functions
resource "aws_iam_policy" "lambda_logging_policy" {
  name = "lambda_logging_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
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

// Policy for store_user_data Lambda - only needs DynamoDB operations on users table
resource "aws_iam_policy" "store_user_data_policy" {
  name = "store_user_data_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
        "Effect" : "Allow",
        "Resource" : aws_dynamodb_table.secdrive_users.arn
      }
    ]
  })
}

// Policy for get_user_data Lambda - needs DynamoDB query and S3 presigned URLs
resource "aws_iam_policy" "get_user_data_policy" {
  name = "get_user_data_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "dynamodb:Query"
        ],
        "Effect" : "Allow",
        "Resource" : [
          aws_dynamodb_table.secdrive_user_files.arn,
          "${aws_dynamodb_table.secdrive_user_files.arn}/index/secdrive_user_id_index"
        ]
      },
      {
        "Action" : [
          "s3:GetObject"
        ],
        "Effect" : "Allow",
        "Resource" : "${aws_s3_bucket.s3_user_data.arn}/*"
      }
    ]
  })
}

// Policy for get_user_profile Lambda - only needs DynamoDB GetItem on users table
resource "aws_iam_policy" "get_user_profile_policy" {
  name = "get_user_profile_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "dynamodb:GetItem"
        ],
        "Effect" : "Allow",
        "Resource" : aws_dynamodb_table.secdrive_users.arn
      }
    ]
  })
}

// Policy for generate_presigned_url Lambda - only needs S3 PutObject for presigned URLs
resource "aws_iam_policy" "generate_presigned_url_policy" {
  name = "generate_presigned_url_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:PutObject"
        ],
        "Effect" : "Allow",
        "Resource" : "${aws_s3_bucket.s3_user_data.arn}/*"
      }
    ]
  })
}

// Policy for confirm_upload Lambda - only needs DynamoDB PutItem on user_files table
resource "aws_iam_policy" "confirm_upload_policy" {
  name = "confirm_upload_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "dynamodb:PutItem"
        ],
        "Effect" : "Allow",
        "Resource" : aws_dynamodb_table.secdrive_user_files.arn
      }
    ]
  })
}

// Policy for generate_data_key Lambda - only needs KMS GenerateDataKey
resource "aws_iam_policy" "generate_data_key_policy" {
  name = "generate_data_key_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "kms:GenerateDataKey"
        ],
        "Effect" : "Allow",
        "Resource" : aws_kms_key.secdrive_encryption_key.arn
      }
    ]
  })
}

// Policy for decrypt_data_key Lambda - only needs KMS Decrypt
resource "aws_iam_policy" "decrypt_data_key_policy" {
  name = "decrypt_data_key_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "kms:Decrypt"
        ],
        "Effect" : "Allow",
        "Resource" : aws_kms_key.secdrive_encryption_key.arn
      }
    ]
  })
}

// Policy for delete_file Lambda - needs DynamoDB operations and S3 DeleteObject
resource "aws_iam_policy" "delete_file_policy" {
  name = "delete_file_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "dynamodb:GetItem",
          "dynamodb:DeleteItem"
        ],
        "Effect" : "Allow",
        "Resource" : aws_dynamodb_table.secdrive_user_files.arn
      },
      {
        "Action" : [
          "s3:DeleteObject"
        ],
        "Effect" : "Allow",
        "Resource" : "${aws_s3_bucket.s3_user_data.arn}/*"
      }
    ]
  })
}

// IAM Roles for each Lambda function
resource "aws_iam_role" "store_user_data_role" {
  name               = "store_user_data_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "get_user_data_role" {
  name               = "get_user_data_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "get_user_profile_role" {
  name               = "get_user_profile_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "generate_presigned_url_role" {
  name               = "generate_presigned_url_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "confirm_upload_role" {
  name               = "confirm_upload_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "generate_data_key_role" {
  name               = "generate_data_key_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "decrypt_data_key_role" {
  name               = "decrypt_data_key_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "delete_file_role" {
  name               = "delete_file_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Policy attachments for each Lambda function
resource "aws_iam_role_policy_attachment" "store_user_data_logging" {
  role       = aws_iam_role.store_user_data_role.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

resource "aws_iam_role_policy_attachment" "store_user_data_policy_attachment" {
  role       = aws_iam_role.store_user_data_role.name
  policy_arn = aws_iam_policy.store_user_data_policy.arn
}

resource "aws_iam_role_policy_attachment" "get_user_data_logging" {
  role       = aws_iam_role.get_user_data_role.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

resource "aws_iam_role_policy_attachment" "get_user_data_policy_attachment" {
  role       = aws_iam_role.get_user_data_role.name
  policy_arn = aws_iam_policy.get_user_data_policy.arn
}

resource "aws_iam_role_policy_attachment" "get_user_profile_logging" {
  role       = aws_iam_role.get_user_profile_role.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

resource "aws_iam_role_policy_attachment" "get_user_profile_policy_attachment" {
  role       = aws_iam_role.get_user_profile_role.name
  policy_arn = aws_iam_policy.get_user_profile_policy.arn
}

resource "aws_iam_role_policy_attachment" "generate_presigned_url_logging" {
  role       = aws_iam_role.generate_presigned_url_role.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

resource "aws_iam_role_policy_attachment" "generate_presigned_url_policy_attachment" {
  role       = aws_iam_role.generate_presigned_url_role.name
  policy_arn = aws_iam_policy.generate_presigned_url_policy.arn
}

resource "aws_iam_role_policy_attachment" "confirm_upload_logging" {
  role       = aws_iam_role.confirm_upload_role.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

resource "aws_iam_role_policy_attachment" "confirm_upload_policy_attachment" {
  role       = aws_iam_role.confirm_upload_role.name
  policy_arn = aws_iam_policy.confirm_upload_policy.arn
}

resource "aws_iam_role_policy_attachment" "generate_data_key_logging" {
  role       = aws_iam_role.generate_data_key_role.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

resource "aws_iam_role_policy_attachment" "generate_data_key_policy_attachment" {
  role       = aws_iam_role.generate_data_key_role.name
  policy_arn = aws_iam_policy.generate_data_key_policy.arn
}

resource "aws_iam_role_policy_attachment" "decrypt_data_key_logging" {
  role       = aws_iam_role.decrypt_data_key_role.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

resource "aws_iam_role_policy_attachment" "decrypt_data_key_policy_attachment" {
  role       = aws_iam_role.decrypt_data_key_role.name
  policy_arn = aws_iam_policy.decrypt_data_key_policy.arn
}

resource "aws_iam_role_policy_attachment" "delete_file_logging" {
  role       = aws_iam_role.delete_file_role.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

resource "aws_iam_role_policy_attachment" "delete_file_policy_attachment" {
  role       = aws_iam_role.delete_file_role.name
  policy_arn = aws_iam_policy.delete_file_policy.arn
}