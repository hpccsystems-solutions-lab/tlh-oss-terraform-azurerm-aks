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

variable "names" {
  description = "Names to be applied to resources"
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
    min_count = number
    max_count = number
    tags      = map(string)
  }))

  validation {
    condition     = (length([for pool in var.node_pools : pool.name if(length(pool.name) > 11 && lower(pool.os_type) == "linux")]) == 0)
    error_message = "Node pool name must be fewer than 12 characters for os_type Linux."
  }

  validation {
    condition     = (length([for pool in var.node_pools : pool.name if(length(pool.name) > 5 && lower(pool.os_type) == "windows")]) == 0)
    error_message = "Node pool name must be fewer than 6 characters for os_type Windows."
  }

  validation {
    condition     = (length([for pool in var.node_pools : pool.name if pool.lifecycle != "normal"]) == 0)
    error_message = "Only lifecycle type \"normal\" is currently supported."
  }
}

variable "network_plugin" {
  description = "Kubernetes Network Plugin (kubenet or azure)"
  type        = string
  default     = "kubenet"

  validation {
    condition     = contains(["kubenet", "azure"], lower(var.network_plugin))
    error_message = "Network plugin must be kubenet or azure."
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

variable "custom_route_table_ids" {
  description = "Custom route tables used by node pool subnets."
  type        = map(string)
  default     = {}
}

variable "additional_priority_classes" {
  type = map(object({
    description = string
    value       = number
    labels      = map(string)
    annotations = map(string)
  }))
  default     = null
  description = "A map defining additional priority classes. Refer to [this link](https://github.com/LexisNexis-RBA/terraform-kubernetes-priority-class) for additional information."
}

variable "additional_storage_classes" {
  type = map(object({
    labels                 = map(string)
    annotations            = map(string)
    storage_provisioner    = string
    parameters             = map(string)
    reclaim_policy         = string
    mount_options          = list(string)
    volume_binding_mode    = string
    allow_volume_expansion = bool
  }))
  default     = null
  description = "A map defining additional storage classes. Refer to [this link](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/blob/main/modules/storage-classes/README.md) for additional information."

  validation {
    condition = var.additional_storage_classes == null ? true : (length([for strgclass in var.additional_storage_classes : strgclass.reclaim_policy if strgclass.reclaim_policy != "Retain"]) == 0 ||
    length([for strgclass in var.additional_storage_classes : strgclass.reclaim_policy if strgclass.reclaim_policy != "Delete"]) == 0)
    error_message = "The reclaim policy setting must be set to 'Delete' or 'Reclaim'."
  }

  validation {
    condition = var.additional_storage_classes == null ? true : (length([for strgclass in var.additional_storage_classes : strgclass.storage_provisioner if strgclass.storage_provisioner != "kubernetes.io/azure-file"]) == 0 ||
    length([for strgclass in var.additional_storage_classes : strgclass.storage_provisioner if strgclass.storage_provisioner != "kubernetes.io/azure-disk"]) == 0)
    error_message = "The storage provisioner setting must be set to 'kubernetes.io/azure-file' or 'kubernetes.io/azure-disk'."
  }

  validation {
    condition = var.additional_storage_classes == null ? true : (length([for strgclass in var.additional_storage_classes : strgclass.volume_binding_mode if strgclass.volume_binding_mode != "Immediate"]) == 0 ||
    length([for strgclass in var.additional_storage_classes : strgclass.volume_binding_mode if strgclass.volume_binding_mode != "WaitForFirstConsumer"]) == 0)
    error_message = "The volume binding mode setting must be set to 'Immediate' or 'WaitForFirstConsumer'."
  }
}

variable "namespaces" {
  description = "List of namespaces to create on the cluster."
  type        = list(string)
  default     = []
}

variable "secrets" {
  description = "Map of secrets to apply to the cluster, the namespace must already exist or be in the namespaces variable."
  type = map(object({
    name      = string
    namespace = string
    type      = string
    data      = map(string)
  }))
  default = {}
}

variable "configmaps" {
  description = "Map of configmaps to apply to the cluster, the namespace must already exist or be in the namespaces variable."
  type = map(object({
    name      = string
    namespace = string
    data      = map(string)
  }))
  default = {}
}

variable "cert_manager_dns_zone_name" {
  type        = string
  description = "The name of the DNS zone that cert-manager will use (only one is supported at this time)"
}

variable "cert_manager_dns_zone_resource_group_name" {
  type        = string
  description = "The name of the resource group containing the DNS zone that cert-manager will use"
}