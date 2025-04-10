resource "aws_dynamodb_table" "secdrive_user_files" { // Create a DynamoDB table for the user files
  name         = "secdrive_user_files"
  billing_mode = local.dynamodb_billing_mode // Set the billing mode to pay per request
  hash_key     = "file_id"                // Set the hash key (primary key) to product_id

  attribute {
    name = "file_id"
    type = "S"
  }

  attribute { // Additional tag attribute for the global secondary index
    name = "user_id"
    type = "S"
  }

  global_secondary_index { // Create a global secondary index for the tag attribute to allow querying by tag
    name            = "secdrive_user_id_index"
    hash_key        = "user_id"
    projection_type = "ALL"
  }
}

resource "aws_dynamodb_table" "secdrive_users" { // Create a DynamoDB table for the users
  name         = "secdrive_users"
  billing_mode = local.dynamodb_billing_mode // Set the billing mode to pay per request
  hash_key     = "user_id"                   // Set the hash key (primary key) to user_id

  attribute {
    name = "user_id"
    type = "S"
  }

}