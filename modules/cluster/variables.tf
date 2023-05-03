variable "location" {
  description = "Azure region in which to build resources."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "Name of the Resource Group to deploy the AKS cluster service to, must already exist."
  type        = string
  nullable    = false
}

variable "cluster_name" {
  description = "Name of the Azure Kubernetes managed cluster to create, also used as a prefix in names of related resources."
  type        = string
  nullable    = false
}

variable "cluster_version_full" {
  description = "The full Kubernetes version of the Azure Kubernetes managed cluster."
  type        = string
  nullable    = false
}

variable "network_plugin" {
  description = "Kubernetes Network Plugin, \"kubenet\" & \"azure\" are supported."
  type        = string
  nullable    = false
}

variable "sku_tier" {
  description = "Pricing tier for the Azure Kubernetes Service managed cluster; \"free\", \"standard\" & \"paid\" (deprecated) are supported."
  type        = string
  nullable    = false
}

variable "fips" {
  description = "If true, the cluster will be created with FIPS 140-2 mode enabled; this can't be changed once the cluster has been created."
  type        = bool
  nullable    = false
}

variable "workload_identity" {
  description = "If the cluster has workload identity enabled."
  type        = bool
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Azure Kubernetes managed cluster public API server endpoint is enabled."
  type        = bool
  nullable    = false
}

variable "cluster_endpoint_access_cidrs" {
  description = "List of CIDR blocks which can access the Azure Kubernetes managed cluster API server endpoint."
  type        = list(string)
  nullable    = false
}

variable "subnet_id" {
  description = "ID of the subnet."
  type        = string
  nullable    = false
}

variable "route_table_id" {
  description = "ID of the route table."
  type        = string
  nullable    = false
}

variable "podnet_cidr_block" {
  description = "CIDR range for pod IP addresses when using the kubenet network plugin."
  type        = string
  nullable    = false
}

variable "nat_gateway_id" {
  description = "ID of a user-assigned NAT Gateway to use for cluster egress traffic, if not set a cluster managed load balancer will be used."
  type        = string
  nullable    = true
}

variable "managed_outbound_ip_count" {
  description = "Count of desired managed outbound IPs for the cluster managed load balancer. Ignored if NAT gateway is specified, must be between 1 and 100 inclusive."
  type        = number
  nullable    = false
}

variable "managed_outbound_ports_allocated" {
  description = "Number of desired SNAT port for each VM in the cluster managed load balancer. Ignored if NAT gateway is specified, must be between 0 and 64000 inclusive."
  type        = number
  nullable    = false
}

variable "managed_outbound_idle_timeout" {
  description = "Desired outbound flow idle timeout in seconds for the cluster managed load balancer. Ignored if NAT gateway is specified, must be between 240 and 7200 inclusive."
  type        = number
  nullable    = false
}

variable "admin_group_object_ids" {
  description = "AD Object IDs to be added to the cluster admin group, if not set the current user will be made a cluster administrator."
  type        = list(string)
  nullable    = false
}

variable "bootstrap_name" {
  description = "Name to use for the bootstrap node group."
  type        = string
  nullable    = false
}

variable "bootstrap_vm_size" {
  description = "VM size to use for the bootstrap node group."
  type        = string
  nullable    = false
}

variable "control_plane_logging" {
  description = "Control plane logging configuration."
  type = object({
    log_analytics = object({
      enabled                       = bool
      external_workspace            = bool
      workspace_id                  = string
      profile                       = string
      additional_log_category_types = list(string)
      retention_enabled             = bool
      retention_days                = number
    })
    storage_account = object({
      enabled                       = bool
      id                            = string
      profile                       = string
      additional_log_category_types = list(string)
      retention_enabled             = bool
      retention_days                = number
    })
  })
  nullable = false

  validation {
    condition     = var.control_plane_logging.log_analytics.enabled || var.control_plane_logging.storage_account.enabled
    error_message = "Control plane logging must be enabled."
  }

  validation {
    condition     = !var.control_plane_logging.log_analytics.enabled || (!var.control_plane_logging.log_analytics.external_workspace || var.control_plane_logging.log_analytics.workspace_id != null)
    error_message = "Control plane logging to a log analytics external workspace requires a workspace ID."
  }

  validation {
    condition     = !var.control_plane_logging.log_analytics.enabled || (var.control_plane_logging.log_analytics.profile != null && contains(["all", "audit-write-only", "minimal", "empty", "recommended", "limited"], coalesce(var.control_plane_logging.log_analytics.profile, "empty")))
    error_message = "Control plane logging to a log analytics external workspace requires a profile."
  }

  validation {
    condition     = !var.control_plane_logging.storage_account.enabled || var.control_plane_logging.storage_account.id != null
    error_message = "Control plane logging to a storage account requires an ID."
  }

  validation {
    condition     = !var.control_plane_logging.storage_account.enabled || (var.control_plane_logging.storage_account.profile != null && contains(["all", "audit-write-only", "minimal", "empty", "recommended", "limited"], coalesce(var.control_plane_logging.storage_account.profile, "empty")))
    error_message = "Control plane logging to a storage account requires profile."
  }
}

variable "maintenance_window_offset" {
  description = "Maintenance window offset to utc."
  type        = number
  nullable    = true
}

variable "maintenance_window_allowed_days" {
  description = "List of allowed days covering the maintenance window."
  type        = list(string)
  nullable    = false
}

variable "maintenance_window_allowed_hours" {
  description = "List of allowed hours covering the maintenance window."
  type        = list(number)
  nullable    = false
}

variable "maintenance_window_not_allowed" {
  description = "Array of not allowed blocks including start and end times in rfc3339 format. A not allowed block takes priority if it overlaps an allowed blocks in a maintenance window."
  type = list(object({
    start = string
    end   = string
  }))
  nullable = false
}

variable "oms_agent" {
  description = "If the OMS agent addon should be installed."
  type        = bool
  nullable    = false
}

variable "oms_agent_log_analytics_workspace_id" {
  description = "ID of the log analytics workspace for the OMS agent."
  type        = string
  nullable    = true
}

variable "windows_support" {
  description = "If the Kubernetes cluster should support Windows nodes."
  type        = bool
  nullable    = false
}

variable "storage" {
  description = "Azure storage CSI driver profile."
  type = object({
    file = bool
    blob = bool
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
    cluster_create = number
    cluster_update = number
    cluster_read   = number
    cluster_delete = number
  })
  nullable = false
}
