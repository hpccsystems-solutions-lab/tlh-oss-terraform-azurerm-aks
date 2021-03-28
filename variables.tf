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
  description = "The name of the AKS cluster to create, also used as a prefix in names of related resources."
  type        = string
}

variable "cluster_version" {
  description = "The Kubernetes version to use for the AKS cluster."
  type        = string
  default     = "1.18"

  validation {
    condition     = contains(["1.20", "1.19", "1.18", "1.17"], var.cluster_version)
    error_message = "This module only supports EKS versions 1.20, 1.19, 1.18 & 1.17."
  }
}

variable "vm_types" {
  description = "Extend or overwrite the default vm types map."
  type        = map(string)
  default     = {}
}

variable "node_pool_defaults" {
  description = "Override default values for the node pools, this will NOT override the values that the module sets directly."
  type        = any
  default     = {}
}

variable "node_pool_taints" {
  description = "Extend or overwrite the default node pool taints to apply based on the node pool tier and/or lifecycle (by default ingress & egress taints are set but these can be overridden)."
  type        = map(string)
  default     = {}
}

variable "node_pool_tags" {
  description = "Additional tags for all workers."
  type        = map(string)
  default     = {}
}

variable "default_node_pool" {
  description = "Override default values for default node pool."
  type        = any
  default     = {}
}

variable "node_pools" {
  description = "Node pool definitions."
  type = list(object({
    name      = string
    tier      = string
    lifecycle = string
    vm_size   = string
    os_type   = string
    subnet    = string
    min_count = number
    max_count = number
    tags      = map(string)
  }))

  validation {
    condition     = (length([for pool in var.node_pools: pool.name if (length(pool.name) > 11 && lower(pool.os_type) == "linux")]) == 0)
    error_message = "Node pool name must be fewer than 12 characters for os_type Linux."
  }

  validation {
    condition     = (length([for pool in var.node_pools: pool.name if (length(pool.name) > 5 && lower(pool.os_type) == "windows")]) == 0)
    error_message = "Node pool name must be fewer than 6 characters for os_type Windows."
  }

  validation {
    condition     = (length([for pool in var.node_pools: pool.name if pool.lifecycle != "normal"]) == 0)
    error_message = "Only lifecycle type \"normal\" is currently supported."
  }
}

variable "network_plugin" {
  description = "Kubernetes Network Plugin (kubenet or AzureCNI)"
  type        = string
  default     = "kubenet"

  validation {
    condition     = contains(["kubenet", "azurecni"], lower(var.network_plugin))
    error_message = "Network plugin must be kubenet or AzureCNI."
  }
}

variable "subnets" {
  description = "Subnet info."
  type = object(
    {
      private = object(
        {
          id                          = string
          resource_group_name         = string
          network_security_group_name = string
        }
      )
      public = object(
        {
          id                          = string
          resource_group_name         = string
          network_security_group_name = string
        }
      )
    }
  )
}