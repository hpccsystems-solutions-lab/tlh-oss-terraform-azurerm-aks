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
    condition     = contains(["AzurePublicCloud", "AzureUSGovernmentCloud"], var.azure_environment)
    error_message = "The \"azure_environment\" variable must be either \"AzurePublicCloud\" or \"AzureUSGovernmentCloud\"."
  } 
}

variable "cluster_name" {
  description = "The name of the AKS cluster."
  type        = string
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group of your AKS cluster"
}

variable "resource_group_location" {
  type        = string
  description = "The location of the resource group of your AKS cluster"
}

variable "dns_zones" {
  description = "The name and resource group of the DNS zone associated with your Azure subscription"
  type        = map(string)
}

variable "letsencrypt_environment" {
  description = "Let's Encrypt enfironment to use, staging or production."
  type        = string

  validation {
    condition     = contains(["staging", "production"], lower(var.letsencrypt_environment))
    error_message = "The \"letsencrypt_environment\" variable must be either \"staging\" or \"production\"."
  }
}

variable "additional_issuers" {
  description = "Issuers in addition to the default Let's Encrypt cluster issuer to add to the cluster."
  type        = map(any)
}

variable "default_issuer_kind" {
  description = "The default issuer kind."
  type        = string
}

variable "default_issuer_name" {
  description = "The default issuer."
  type        = string
}

variable "ingress_internal_core_domain" {
  description = "The domain to use for internal ingress resources."
  type        = string
}

variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
}