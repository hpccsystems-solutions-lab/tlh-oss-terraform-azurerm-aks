variable "api_server_authorized_ip_ranges" {
  description = "Public CIDR ranges to whitelist access to the Kubernetes API server, if not set defaults to `0.0.0.0/0`."
  type = map(string)
  default = null
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

variable "cluster_name" {
  description = "The name of the AKS cluster to create, also used as a prefix in names of related resources."
  type        = string
}

variable "cluster_version" {
  description = "The Kubernetes minor version to use for the AKS cluster."
  type        = string
  default     = "1.20"

  validation {
    condition     = contains(["1.20", "1.19"], var.cluster_version)
    error_message = "This module only supports AKS versions 1.20 & 1.19."
  }
}

variable "core_services_config" {
  description = "Configuration options for core platform services"
  type        = any
}

variable "location" {
  description = "Azure region in which to build resources."
  type        = string
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

variable "node_pool_defaults" {
  description = "Override default values for the node pools, this will NOT override the values that the module sets directly."
  type        = any
  default     = {}
}

variable "node_pools" {
  description = "Node pool definitions."
  type = list(object({
    name         = string
    single_vmss  = bool
    public       = bool
    node_type    = string
    node_size    = string
    min_capacity = number
    max_capacity = number
    labels       = map(string)
    taints       = list(object({
      key    = string
      value  = string
      effect = string
    }))
    tags         = map(string)
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

variable "podnet_cidr" {
  description = "CIDR range for pod IP addresses when using the `kubenet` network plugin."
  type        = string
  default     = "100.65.0.0/16"
}

variable "resource_group_name" {
  description = "The name of the Resource Group to deploy the AKS cluster service to, must already exist."
  type        = string
}

variable "tags" {
  description = "Tags to be applied to cloud resources."
  type        = map(string)
  default     = {}
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

variable "vm_types" {
  description = "Extend or overwrite the default vm types map."
  type        = map(string)
  default     = {}
}
