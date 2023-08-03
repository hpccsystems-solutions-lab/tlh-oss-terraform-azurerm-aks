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

variable "replicas_per_zone" {
  description = "The number of replicas to run per zone."
  type        = number
  nullable    = false
}

variable "extra_env" {
  description = "Extra environment variables."
  type        = map(string)
  nullable    = false
}

variable "secret_env" {
  description = "Extra environment variables from secrets."
  type        = map(string)
  nullable    = false
  sensitive   = true
}

variable "extra_records" {
  description = "Extra records to add to logs."
  type        = map(string)
  nullable    = false
}

variable "lua_scripts" {
  description = "Lua scripts for Fluent Bit."
  type        = map(string)
  nullable    = false
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

variable "raw_filters" {
  description = "Fluent Bit pipeline filters config."
  type        = string
  nullable    = true
}

variable "raw_outputs" {
  description = "Fluent Bit pipeline outputs config."
  type        = string
  nullable    = true
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

variable "resource_overrides" {
  description = "Override resources for containers"
  type = map(object({
    cpu       = number
    cpu_limit = number
    memory    = number
  }))
  nullable = true
}
