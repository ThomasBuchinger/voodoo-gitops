resource "vault_auth_backend" "static" {
  type        = "userpass"
  path        = "static"
  description = "Static Username/Passowrd Authentication for Vault UI"

  tune {
    listing_visibility = "unauth"
  }
}
resource "vault_auth_backend" "approle" {
  type = "approle"
  description = "Auth Backend for ServiceAccounts outside of Kubernetes"
}

module "approle_green" {
  source = "./modules/approle"

  name = "green"
  secretid_fetch_mount = "secret"
  secretid_fetch_path = "access/secret-ids"
  secretid_fetch_key = "green"
}

module "kubeconfig" {
  source = "./modules/kubeconfig"

  name = "voodoo"
  api_url = "https://voodoo.buc.sh:6443"

  client_id = module.oidc_kubernetes.client_id
  client_secret = module.oidc_kubernetes.client_secret
  oidc_provider_url = module.oidc_kubernetes.oidc_provider_url
}

# module "green_prod" {
#   source = "./modules/kubeconfig"

#   name = "green-prod"
#   api_url = "https://green-prod.buc.sh:6443"

#   client_id = module.oidc_green_prod.client_id
#   client_secret = module.oidc_green_prod.client_secret
#   oidc_provider_url = module.oidc_green_prod.oidc_provider_url
# }
