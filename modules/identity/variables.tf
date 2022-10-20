variable "location" {
  description = "Azure region in which to build resources."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Resource Group where the Kubernetes cluster should exist."
  type        = string
}

variable "workload_identity" {
  description = "If the cluster has workload identity enabled."
  type        = bool
}

variable "oidc_issuer_url" {
  description = "The OIDC issuer url."
  type        = string
}

variable "name" {
  description = "Name for Azure identity to be used by AAD."
  type        = string
}

variable "subjects" {
  description = "Subjects who can assume the identity."
  type        = list(string)
}

variable "namespace" {
  description = "Kubernetes namespace in which to create identity."
  type        = string
}

variable "labels" {
  description = "Labels to be applied to all Kubernetes resources."
  type        = map(string)
}

variable "roles" {
  description = "Role definitions to apply to the identity."
  type = list(object({
    id    = string
    scope = string
  }))
}

variable "tags" {
  description = "Tags to be applied to all resources."
  type        = map(string)
}
