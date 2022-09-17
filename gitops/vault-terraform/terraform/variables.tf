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

variable "admin_user" {
  type        = string
  sensitive   = false
  default     = "admin"
  description = "username for the default admin user"
}

variable "admin_passwd" {
  type        = string
  sensitive   = true
  description = "password for the default admin"
}


