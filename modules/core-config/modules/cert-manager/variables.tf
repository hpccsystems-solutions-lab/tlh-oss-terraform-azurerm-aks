variable "azure_environment" {
  description = "Azure Cloud Environment."
  type        = string
  nullable    = false
}

variable "tenant_id" {
  description = "ID of the Azure Tenant."
  type        = string
  nullable    = false
}

variable "subscription_id" {
  description = "ID of the subscription."
  type        = string
  nullable    = false
}

variable "location" {
  description = "Azure region in which the AKS cluster is located."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "Name of the resource group containing the AKS cluster."
  type        = string
  nullable    = false
}

variable "dns_resource_group_lookup" {
  description = "Lookup from DNS zone to resource group name."
  type        = map(string)
  nullable    = false
}

variable "cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
  nullable    = false
}

variable "cluster_oidc_issuer_url" {
  description = "The URL of the cluster OIDC issuer."
  type        = string
}

variable "namespace" {
  description = "Namespace to install the Kubernetes resources into."
  type        = string
  nullable    = false
}

variable "labels" {
  description = "Labels to be applied to all Kubernetes resources."
  type        = map(string)
  nullable    = false
}

variable "log_level" {
  description = "Log level."
  type        = string
  nullable    = false
}

variable "acme_dns_zones" {
  description = "DNS zones which can be managed via the ACME protocol."
  type        = list(string)
  nullable    = false
}

variable "additional_issuers" {
  description = "Additional issuers to add to the cluster."
  type        = map(any)
  nullable    = false
}

variable "default_issuer_kind" {
  description = "The default issuer kind."
  type        = string
  nullable    = false
}

variable "default_issuer_name" {
  description = "The default issuer."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  nullable    = false
}

variable "timeouts" {
  description = "Timeout configuration."
  type = object({
    helm_modify = number
  })
  nullable = false
}
