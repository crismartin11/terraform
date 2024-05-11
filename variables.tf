variable "user_creds" {
  description = "User aws credentials"
  type        = map(string)
  sensitive   = true

  # default = {
  #     client_id = "test-credential-a"
  #     client_secret = "test-credential-b"
  # }
}
