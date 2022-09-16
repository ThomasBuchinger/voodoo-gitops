variable "vault_address" {
  type        = string
  sensitive   = false
  default     = "http://vault:8200"
  description = "Vault Root Token"
}
variable "vault_token" {
  type        = string
  sensitive   = true
  description = "Vault Root Token"
}