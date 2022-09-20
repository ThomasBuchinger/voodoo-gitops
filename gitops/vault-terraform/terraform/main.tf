resource "vault_auth_backend" "static" {
  type        = "userpass"
  path        = "static"
  description = "Static Username/Passowrd Authentication for Vault UI"

  tune {
    listing_visibility = "unauth"
  }
}

resource "vault_identity_entity" "admin" {
  name      = "admin"
  policies  = ["admin"]
  metadata  = { }
}

resource "vault_identity_entity_alias" "admin_to_userpass_admin" {
  name            = var.cred_admin_user
  mount_accessor  = vault_auth_backend.static.accessor
  canonical_id    = vault_identity_entity.admin.id
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
