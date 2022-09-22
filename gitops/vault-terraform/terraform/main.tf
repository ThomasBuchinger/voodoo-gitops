resource "vault_auth_backend" "static" {
  type        = "userpass"
  path        = "static"
  description = "Static Username/Passowrd Authentication for Vault UI"

  tune {
    listing_visibility = "unauth"
  }
}

module "kubeconfig" {
  source = "./modules/kubeconfig"

  name = "voodoo"
  api_url = "https://voodoo.buc.sh:6443"

  client_id = module.oidc_kubernetes.client_id
  client_secret = module.oidc_kubernetes.client_secret
  oidc_provider_url = module.oidc_kubernetes.oidc_provider_url
}