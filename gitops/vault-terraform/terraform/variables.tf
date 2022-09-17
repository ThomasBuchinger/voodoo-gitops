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