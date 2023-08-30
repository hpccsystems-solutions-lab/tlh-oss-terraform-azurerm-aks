variable "subscription_id" {
  description = "ID of the subscription."
  type        = string
}

variable "location" {
  description = "Azure region in which the AKS cluster is located."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group containing the AKS cluster."
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster that has been created."
  type        = string
  nullable    = false
}

variable "cluster_version" {
  description = "The Kubernetes version to use for the EKS cluster."
  type        = string
  nullable    = false
}

variable "cluster_oidc_issuer_url" {
  description = "The OIDC issuer url for the cluster."
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

variable "subnet_id" {
  description = "ID of the subnet."
  type        = string
  nullable    = false
}

variable "zones" {
  description = "The number of zones this chart should be run on."
  type        = number
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

variable "resource_overrides" {
  description = "Override resources for containers"
  type = map(object({
    cpu       = number
    cpu_limit = number
    memory    = number
  }))
  nullable = true
}
