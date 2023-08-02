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
}

variable "extra_records" {
  description = "Extra records to add to logs."
  type        = map(string)
  nullable    = false
}

variable "debug" {
  description = "If true all logs will be sent to stdout."
  type        = bool
  nullable    = false
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
    copy   = bool
    config = string
  }))
  nullable = false
}

variable "loki_output" {
  description = "Loki output config."
  type = object({
    enabled       = bool
    host          = string
    port          = number
    node_logs     = bool
    workload_logs = bool
  })
  nullable = false
}

variable "azure_storage_nodes_output" {
  description = "Azure storage output config for node logs."
  type = object({
    enabled     = bool
    id          = string
    container   = string
    path_prefix = string
  })
  nullable = false
}

variable "azure_storage_workloads_output" {
  description = "Azure storage output config for workload logs."
  type = object({
    enabled     = bool
    id          = string
    container   = string
    path_prefix = string
  })
  nullable = false
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

variable "experimental_memory_override" {
  description = "Provide experimental feature flag configuration."
  type        = string
  nullable    = true
}
