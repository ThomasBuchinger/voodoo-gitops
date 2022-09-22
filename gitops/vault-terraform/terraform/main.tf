resource "vault_auth_backend" "static" {
  type        = "userpass"
  path        = "static"
  description = "Static Username/Passowrd Authentication for Vault UI"

  tune {
    listing_visibility = "unauth"
  }
}

resource "vault_identity_group" "admins" {
  name     = "admins"
  type     = "internal"
  metadata = { }
  policies = [
    "admins"
  ]
  member_entity_ids = [
    vault_identity_entity.admin.id
  ]
}


resource "vault_identity_group" "users" {
  name     = "users"
  type     = "internal"
  metadata = { }
  policies = [ ]
  member_group_ids = [
    vault_identity_group.admins.id
  ]
}

resource "vault_identity_entity" "admin" {
  name      = "admin"
  metadata  = {
    login_name = "admin"
    email = "thomas@buc.sh"
  }
}

resource "vault_identity_entity_alias" "admin_to_static_admin" {
  name            = var.cred_admin_user
  mount_accessor  = vault_auth_backend.static.accessor
  canonical_id    = vault_identity_entity.admin.id
}

resource "vault_generic_endpoint" "static_admin" {
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

resource "vault_generic_endpoint" "static_public" {
  depends_on           = [vault_auth_backend.static]
  path                 = "auth/static/users/public"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["public_reader"],
  "password": "public"
}
EOT
}

