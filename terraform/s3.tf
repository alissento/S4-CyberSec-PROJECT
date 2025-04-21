resource "aws_s3_bucket" "s3b" {    // Defining the S3 bucket
  bucket        = local.domain_name // My own personal domain for testing
  force_destroy = true
}

resource "aws_s3_bucket_cors_configuration" "s3_cors" { // Defining the CORS configuration for the S3 bucket
  bucket = aws_s3_bucket.s3b.id
  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["https://${local.domain_name}"]
  }
}

resource "aws_s3_bucket_public_access_block" "s3b_enable_public_access" { // Disabling public access block
  bucket = aws_s3_bucket.s3b.id

  block_public_acls   = false
  block_public_policy = false
}
resource "aws_s3_bucket_website_configuration" "website_s3b" { // Defining the website settings for S3 bucket
  bucket = aws_s3_bucket.s3b.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}
resource "aws_s3_bucket_policy" "bucket_policy_for_website" { // Setting the bucket policy
  bucket = aws_s3_bucket.s3b.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.s3b.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.s3b_enable_public_access]
}

resource "aws_s3_bucket" "s3_user_data" {
  bucket        = "secdrive-user-data-nknez"
  force_destroy = true
}

