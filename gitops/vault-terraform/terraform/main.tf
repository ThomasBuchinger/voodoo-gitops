resource "vault_auth_backend" "static" {
  type        = "userpass"
  path        = "static"
  description = "Static Username/Passowrd Authentication for Vault UI"

  tune {
    max_lease_ttl      = "90000s"
    listing_visibility = "unauth"
  }
}