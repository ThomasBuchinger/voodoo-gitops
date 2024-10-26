variable "vault_address" {
  type        = string
  sensitive   = false
  default     = "http://vault:8200"
  description = "Vault URL"
}
variable "vault_role" {
  type        = string
  sensitive   = false
  default     = "terraform"
  description = "Vault Role to authenticate with"
}

variable "cred_admin_user" {
  type        = string
  sensitive   = false
  default     = "admin"
  description = "username for the default admin user"
}

variable "cred_admin_password" {
  type        = string
  sensitive   = true
  description = "password for the default admin"
}


