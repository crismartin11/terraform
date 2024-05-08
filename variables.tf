variable "user_creds" {
    description = "User aws credentials"
    type = map(string)
    sensitive = true

    default = {
        client_id = "a"
        client_secret = "b"
    }
}
