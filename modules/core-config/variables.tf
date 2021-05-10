variable "azure_tenant_id" {
  type        = string
  description = "The GUID of your Azure tenant"

  validation {
    condition     = can(regex("[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}", var.azure_tenant_id))
    error_message = "The \"azure_tenant_id\" variable must be a GUID (xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "azure_subscription_id" {
  type        = string
  description = "The GUID of your Azure subscription"

  validation {
    condition     = can(regex("[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}", var.azure_subscription_id))
    error_message = "The \"azure_subscription_id\" variable must be a GUID (xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "tags" {
  description = "Tags to be applied to all resources."
  type        = map(string)
}

variable "namespaces" {
  description = "List of namespaces to create on the cluster."
  type        = list(string)
}

variable "secrets" {
  description = "Map of secrets to apply to the cluster, the namespace must already exist or be in the namespaces variable."
  type = map(object({
    name      = string
    namespace = string
    type      = string
    data      = map(string)
  }))
}

variable "configmaps" {
  description = "Map of configmaps to apply to the cluster, the namespace must already exist or be in the namespaces variable."
  type = map(object({
    name      = string
    namespace = string
    data      = map(string)
  }))
}

variable "cluster_name" {
  description = "The name of the AKS cluster."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the Resource Group where the Kubernetes Cluster exists."
  type        = string
}

variable "location" {
  description = "Azure region in which to build resources."
  type        = string
}

variable "external_dns_zones" {
  description = "DNS Zone details for external-dns."
  type = object({
    names               = list(string)
    resource_group_name = string
  })
  default = null
}

variable "cert_manager_dns_zone" {
  description = "The name and resource group of the DNS zone associated with your Azure subscription"
  type = object({
    name = string
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