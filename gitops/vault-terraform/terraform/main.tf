resource "vault_auth_backend" "static" {
  type        = "userpass"
  path        = "static"
  description = "Static Username/Passowrd Authentication for Vault UI"

  tune {
    max_lease_ttl      = "86400s"
    listing_visibility = "unauth"
  }
}

resource "vault_generic_endpoint" "admin_user" {
  depends_on           = [vault_auth_backend.static]
  path                 = "auth/static/users/${var.cred_admin_user}"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["admin"],
  "password": "${var.cred_admin_password}"
}
EOT
}
