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
  default     = "1.19"

  validation {
    condition     = contains(["1.20", "1.19", "1.18"], var.cluster_version)
    error_message = "This module only supports AKS versions 1.20, 1.19, & 1.18."
  }
}

variable "enable_host_encryption" {
  description = "Should the nodes in this Node Pool have host encryption enabled?"
  type        = bool
  default     = false
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

variable "node_pools" {
  description = "Node pool definitions."
  type = list(object({
    name        = string
    single_vmss = bool
    public      = bool
    vm_size     = string
    os_type     = string
    min_count   = number
    max_count   = number
    labels      = map(string)
    taints      = list(object({
      key    = string
      value  = string
      effect = string
    }))
    tags        = map(string)
  }))

  validation {
    condition     = (length([for pool in var.node_pools : pool.name if(length(pool.name) > 11 && lower(pool.os_type) == "linux")]) == 0)
    error_message = "Node pool name must be fewer than 12 characters for os_type Linux."
  }

  validation {
    condition     = (length([for pool in var.node_pools : pool.name if(length(pool.name) > 5 && lower(pool.os_type) == "windows")]) == 0)
    error_message = "Node pool name must be fewer than 6 characters for os_type Windows."
  }
}

variable "virtual_network" {
  description = "Virtual network configuration."
  type        = object({
    subnets = object({
      private = object({ 
        id = string
      })
      public = object({
        id = string
      })
    })
    route_table_id = string
  })
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

variable "pod_cidr" {
  description = "used for pod IP addresses"
  type        = string
  default     = "100.65.0.0/16"
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

variable "azuread_clusterrole_map" {
  description = "Map of Azure AD User and Group Ids to configure in Kubernetes clusterrolebindings"
  type = object(
    {
      cluster_admin_users   = map(string)
      cluster_view_users    = map(string)
      standard_view_users   = map(string)
      standard_view_groups  = map(string)
    }
  )
  default = {
    cluster_admin_users  = {}
    cluster_view_users   = {}
    standard_view_users  = {}
    standard_view_groups = {}
  }
}

variable "core_services_config" {
  description = "Configuration options for core platform services"
  type        = any
}
