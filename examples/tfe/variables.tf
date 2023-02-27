variable "default_connection_info" {
  description = "Vault AzureAD engine info; this variable is populated by the Terraform Enterprise workspace."
  type = object({ subscription_id = string
    tenant_id     = string
    vault_backend = string
    vault_role    = string
    vault_token   = string
  })
  nullable  = false
  sensitive = true
}

variable "aad_group_id" {
  description = "Group id of the Vault Service Principal; this variable is populate by the Terraform Enterprise workspace."
  type        = string
  nullable    = false
}
