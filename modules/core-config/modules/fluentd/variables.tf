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

variable "cluster_name" {
  description = "Name of the Azure Kubernetes managed cluster."
  type        = string
  nullable    = false
}

variable "workload_identity" {
  description = "If the cluster has workload identity enabled."
  type        = bool
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

variable "zones" {
  description = "The number of zones this chart should be run on."
  type        = number
  nullable    = false
}

variable "image_repository" {
  description = "Custom image repository to use for the Fluentd image, image_tag must also be set."
  type        = string
  nullable    = true
}

variable "image_tag" {
  description = "Custom image tag to use for the Fluentd image, image_repository must also be set."
  type        = string
  nullable    = true
}

variable "additional_env" {
  description = "Additional environment variables."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "debug" {
  description = "If true all logs will be sent to stdout."
  type        = bool
  nullable    = false
  default     = true
}

variable "filters" {
  description = "Global filter configuration."
  type        = string
  nullable    = true
}

variable "route_config" {
  description = "list of route configuration."
  type = list(object({
    match  = string
    label  = string
    copy   = optional(bool, false)
    config = string
  }))
  nullable = false
  default  = []
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  nullable    = false
}

variable "experimental_memory_override" {
  description = "Provide experimental feature flag configuration."
  type        = string
  nullable    = true
}
