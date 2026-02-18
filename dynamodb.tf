resource "aws_dynamodb_table" "url_shortener" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "slug"

  attribute {
    name = "slug"
    type = "S"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = false
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = var.dynamodb_table_name
  }
}
