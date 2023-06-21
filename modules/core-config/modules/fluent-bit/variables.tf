variable "location" {
  description = "Azure location to target."
  type        = string
  nullable    = false
}

variable "cluster_name" {
  description = "Name of the Azure Kubernetes Service managed cluster to create, also used as a prefix in names of related resources. This must be lowercase and contain the pattern \"aks-{ordinal}\"."
  type        = string
  nullable    = false
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

variable "aggregator" {
  description = "Aggregator type."
  type        = string
  nullable    = false
}

variable "aggregator_host" {
  description = "Aggregator host."
  type        = string
  nullable    = false
}

variable "aggregator_forward_port" {
  description = "Port that the aggregator is using for forward."
  type        = number
  nullable    = false
}

variable "multiline_parsers" {
  description = "Multiline parsers to configure."
  type = map(object({
    rules = list(object({
      name           = string
      pattern        = string
      next_rule_name = string
    }))
    workloads = list(object({
      namespace  = string
      pod_prefix = string
    }))
  }))
  nullable = false
}

variable "timeouts" {
  description = "Timeout configuration."
  type = object({
    helm_modify = number
  })
  nullable = false
}
