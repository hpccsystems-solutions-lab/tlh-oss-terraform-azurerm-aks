variable "azure_subscription_id" {
  type        = string
  description = "The GUID of your Azure subscription"

  validation {
    condition     = can(regex("[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}", var.azure_subscription_id))
    error_message = "The \"azure_subscription_id\" variable must be a GUID (xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "name" {
   description = "name of clusterIssuer"
   type        = string
}

variable "namespace" {
  description = "kubernetes namespace in which to create identity"
  type        = string
}

variable "azure_environment" {
  description = "Azure Cloud Environment."
  type        = string
  default     = "AzurePublicCloud"

  validation {
    condition     = contains(["AzurePublicCloud"], var.azure_environment)
    error_message = "The \"azure_environment\" variable must be a \"AzurePublicCloud\"."
  }
}

variable "dns_zone" {
  description = "The name and resource group of the DNS zone associated with your Azure subscription"
  type = object({
    name = string
    resource_group_name = string
  })
  default = {
    name = ""
    resource_group_name = ""
  }
}

variable "letsencrypt_email" {
  description = "Email address for expiration notifications."
  type        = string
  default     = ""
}

variable "letsencrypt_endpoint" {
  description = "letsencrypt endpoint (https://letsencrypt.org/docs/acme-protocol-updates)."
  type        = string
}
