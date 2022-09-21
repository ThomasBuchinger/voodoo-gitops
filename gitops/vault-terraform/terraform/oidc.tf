
resource "vault_identity_oidc_provider" "cluster_internal" {
  name = "cluster_internal"
  https_enabled = false
  issuer_host = "vault.default.svc"
  allowed_client_ids = [
    module.oidc_kubernetes.client_id
  ]
  scopes_supported = [
    vault_identity_oidc_scope.scope_groups.name
  ]
}
resource "vault_identity_oidc_provider" "external" {
  name = "global_oidc"
  https_enabled = true
  issuer_host = "vault.buc.sh"
  allowed_client_ids = [
    # module.oidc_kubernetes.client_id
  ]
  scopes_supported = [
    # vault_identity_oidc_scope.scope_groups.name
  ]
}

resource "vault_identity_oidc_scope" "scope_groups" {
  name        = "groups"
  description = "Groups scope."
  template    = jsonencode(
    {
      groups = "{{identity.entity.groups.names}}",
    }
  )
}

module "oidc_kubernetes" {
  source = "./modules/oidc_client"

  client_name = "kubelogin"
  provider_url = vault_oidc_provider.cluster_internal.issuer
  authorized_users = [
    vault_identity_entity.admin.id
  ]
}