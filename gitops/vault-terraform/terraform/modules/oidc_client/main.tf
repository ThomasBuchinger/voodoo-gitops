

resource "vault_identity_oidc_key" "key" {
  name               = var.client_name
  allowed_client_ids = ["*"]
  rotation_period    = 3600
  verification_ttl   = 3600
}


resource "vault_identity_oidc_assignment" "authorized_groups" {
  name       = var.client_name
  entity_ids = var.authorized_users
  group_ids  = var.authorized_users
}
resource "vault_identity_oidc_client" "client_config" {
  name          = var.client_name
  key           = vault_identity_oidc_key.key.name
  redirect_uris = [
    "http://127.0.0.1:9200/v1/auth-methods/oidc:authenticate:callback",
    "http://127.0.0.1:8251/callback",
    "http://127.0.0.1:8080/callback"
  ]
  assignments = [
    "allow_all"
  ]
  id_token_ttl     = 2400
  access_token_ttl = 7200
}

resource "vault_kv_secret_v2" "generic_secret" {
  mount = "secrets"
  name = "cluster/oidc/${var.client_name}"
  data_json = jsonencode({
    "client_name" = var.client_name,
    "client_id" = vault_identity_oidc_client.client_config.client_id,
    "client_secret" = vault_identity_oidc_client.client_config.client_secret
  })
}

variable "client_name" {
  type = string
}

variable "authorized_users" {
  type = list(string)
  default = [ ]
}
variable "authorized_groups" {
  type = list(string)
  default = [ ]
}

output "client_id" {
  value = vault_identity_oidc_client.client_config.client_id
}

output "client_secret" {
  value = vault_identity_oidc_client.client_config.client_secret
  sensitive = true
}
