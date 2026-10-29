resource "aws_dynamodb_table" "this" {
  name         = "users-dev"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "users-dev"
    Environment = "dev"
  }
}
