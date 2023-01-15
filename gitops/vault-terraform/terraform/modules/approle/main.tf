locals {
  role_name = "external-kubernetes-${var.name}"
  role_id = var.name
}

data "vault_kv_secret_v2" "secret_id" {
  mount = var.secretid_fetch_mount
  name = var.secretid_fetch_path
}

resource "vault_approle_auth_backend_role" "role" {
  backend         = var.approle_path
  role_name       = local.role_name
  role_id         = local.role_id
  token_policies  = concat(["default"], var.policies)
  token_ttl = 300
  token_max_ttl = 300
}

resource "vault_approle_auth_backend_role_secret_id" "secret_id" {
  backend   = var.approle_path
  role_name = vault_approle_auth_backend_role.role.role_name
  secret_id = data.vault_kv_secret_v2.secret_id.data[var.secretid_fetch_key]
  metadata = jsonencode({
    role_name = local.role_name
    role_id = local.role_id
    secretid_secret_mount = var.secretid_fetch_mount
    secretid_secret = "${var.secretid_fetch_mount}/${var.secretid_fetch_path}"
  })
}
variable "name" {
  type = string
}
variable "secretid_fetch_mount" {
  type = string
}

variable "secretid_fetch_path" {
  type = string
}
variable "secretid_fetch_key" {
  type = string
}

variable "approle_path" {
  type = string
  default = "approle"
}

variable "policies" {
  type = list(string)
  description = "Additional Policies for this role"
  default = []
}

output "role_id" {
  description = "Generated RoleID"
  value = vault_approle_auth_backend_role.role.role_id
}
output "secret_id" {
  description = "Generated SecretID"
  value = vault_approle_auth_backend_role_secret_id.secret_id.secret_id
}
