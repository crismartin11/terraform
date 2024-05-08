resource "aws_dynamodb_table" "tf_notes_table" {
  name = "tf-notes-table"
  billing_mode = "PAY_PER_REQUEST"

  
  hash_key = "noteId"
  range_key      = "description"
  
  attribute {
    name = "noteId"
    type = "S"
  }

  attribute {
    name = "description"
    type = "S"
  }
}
