#output "user_creds_id" {
#  value = jsondecode(aws_secretsmanager_secret_version.usercreds_version.secret_string)["client_id"]
#}

#output "user_creds_secret" {
#  value = jsondecode(aws_secretsmanager_secret_version.usercreds_version.secret_string)["client_secret"]
#}