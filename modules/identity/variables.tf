variable "resource_group_name" {
  description = "The name of the Resource Group where the Kubernetes Cluster should exist."
  type        = string
}

variable "location" {
  description = "Azure region in which to build resources."
  type        = string
}

variable "tags" {
  description = "Tags to be applied to all resources."
  type        = map(string)
}

variable "cluster_name" {
  description = "name for AKS cluster"
  type        = string
}

variable "identity_name" {
  description = "name for Azure identity to be used by AAD"
  type        = string
}

variable "namespace" {
  description = "kubernetes namespace in which to create identity"
  type        = string
}

variable "roles" {
  description = "Role definitions to apply to the identity."
  type = list(object({
    role_definition_resource_id = string
    scope                       = string
  }))
}