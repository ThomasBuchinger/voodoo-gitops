terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "3.8.2"
    }
    local = {
      source = "hashicorp/local"
      version = "2.2.3"
    }
  }
}
provider "local" { }

provider "vault" {
  # configuration provided via secrets
  address = var.vault_address
  auth_login {
    method = "kubernetes"
    path   = "auth/kubernetes/login"
    parameters = {
      "role" = var.vault_role
      "jwt"  = file("/var/run/secrets/kubernetes.io/serviceaccount/token")
    }
  }
}
