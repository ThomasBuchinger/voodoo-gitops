

resource "vault_identity_oidc_key" "key" {
  name               = var.client_name
  allowed_client_ids = ["*"]
  rotation_period    = 3600
  verification_ttl   = 3600
}


resource "vault_identity_oidc_assignment" "authorized_groups" {
  name       = var.client_name
  entity_ids = var.authorized_users
  group_ids  = var.authorized_groups
}
resource "vault_identity_oidc_client" "client_config" {
  name          = var.client_name
  key           = vault_identity_oidc_key.key.name
  redirect_uris = [
    var.redirect_url
  ]
  assignments = [
    vault_identity_oidc_assignment.authorized_groups.name
  ]
  id_token_ttl     = 2400
  access_token_ttl = 7200
}

resource "vault_kv_secret_v2" "generic_secret" {
  mount = "cluster"
  name = "oidc/${var.client_name}"
  data_json = jsonencode(
    {
      "client_name" = var.client_name,
      "oidc_provider_url" = var.provider_url
      "client_id" = vault_identity_oidc_client.client_config.client_id,
      "client_secret" = vault_identity_oidc_client.client_config.client_secret
    }
  )
}

variable "client_name" {
  type = string
}
variable "provider_url" {
  type = string
}
variable "redirect_url" {
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

output "oidc_provider_url" {
  value = var.provider_url
}
