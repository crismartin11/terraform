resource "aws_secretsmanager_secret" "usercreds" {
  name = "usercreds3"
}

resource "aws_secretsmanager_secret_version" "usercreds_version" {
  secret_id     = aws_secretsmanager_secret.usercreds.id
  secret_string = jsonencode(var.user_creds)
}