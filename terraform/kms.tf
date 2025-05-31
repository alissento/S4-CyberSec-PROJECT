# KMS Key for client-side encryption
resource "aws_kms_key" "secdrive_encryption_key" {
  description             = "KMS key for SecDrive client-side encryption"
  deletion_window_in_days = 7
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Lambda functions to use the key"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.iam_for_lambda.arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "SecDrive Encryption Key"
  }
}

resource "aws_kms_alias" "secdrive_encryption_key_alias" {
  name          = "alias/secdrive-encryption"
  target_key_id = aws_kms_key.secdrive_encryption_key.key_id
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}
