
resource "vault_identity_oidc_provider" "global" {
  name = "global"
  https_enabled = true
  issuer_host = "vault.buc.sh"
  allowed_client_ids = [
    module.oidc_kubernetes.client_id
  ]
  scopes_supported = [
    vault_identity_oidc_scope.scope_user.name,
    vault_identity_oidc_scope.scope_groups.name
  ]
}
resource "vault_identity_oidc_scope" "scope_user" {
  name        = "username"
  description = "username"
  template    = "{\"username\":{{identity.entity.name}}}"
}

resource "vault_identity_oidc_scope" "scope_groups" {
  name        = "groups"
  description = "Groups scope."
  template    = "{\"groups\":{{identity.entity.groups.names}}}"
}

module "oidc_kubernetes" {
  source = "./modules/oidc_client"

  client_name = "kubelogin"
  provider_url = vault_identity_oidc_provider.global.issuer
  redirect_url = "http://localhost:8000"
  authorized_users = [
    vault_identity_entity.admin.id
  ]
}