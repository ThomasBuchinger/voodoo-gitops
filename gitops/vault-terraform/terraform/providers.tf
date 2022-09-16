terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "3.8.2"
    }
  }
}

provider "vault" {
  # configuration provided via secrets
  address = var.vault_address
  token   = var.token
}