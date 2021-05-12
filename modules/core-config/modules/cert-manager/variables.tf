variable "azure_subscription_id" {
  type        = string
  description = "The GUID of your Azure subscription"

  validation {
    condition     = can(regex("[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}", var.azure_subscription_id))
    error_message = "The \"azure_subscription_id\" variable must be a GUID (xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
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

variable "cluster_name" {
  description = "The name of the AKS cluster."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group containing your Kubernetes cluster"
  type        = string
}

variable "location" {
  description = "Azure region in which to build resources"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
}

variable "namespace" {
  type        = string
  description = "The name of the namespace to contain cert-manager resources"
  default     = "cert-manager"
}

variable "dns_zones" {
  description = "The name and resource group of the DNS zone associated with your Azure subscription"
  type = object({
    names = list(string)
    resource_group_name = string
  })
  default = null
}

variable "letsencrypt_environment" {
  description = "Let's Encrypt enfironment to use, staging or production."
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["staging", "production"], lower(var.letsencrypt_environment))
    error_message = "The \"letsencrypt_environment\" variable must be either \"staging\" or \"production\"."
  }
}

variable "letsencrypt_email" {
  description = "Email address for expiration notifications."
  type        = string
  default     = ""
}