
resource "vault_identity_oidc_provider" "vault_oidc_provider" {
  name = "vault_oidc"
  https_enabled = false
  issuer_host = "127.0.0.1:8200"
  allowed_client_ids = [
    module.oidc_kubernetes.client_id
  ]
}


module "oidc_kubernetes" {
  source = "./modules/oidc_client"

  client_name = "kubelogin"
}