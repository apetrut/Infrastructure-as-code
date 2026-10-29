resource "aws_dynamodb_table" "this" {
  name         = "${var.table_name}-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "${var.table_name}-${var.environment}"
    Environment = var.environment
  }
}
