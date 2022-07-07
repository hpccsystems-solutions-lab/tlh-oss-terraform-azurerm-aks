variable "azure_env" {
  description = "Azure cloud environment type, \"public\" & \"usgovernment\" are supported."
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "usgovernment"], var.azure_env)
    error_message = "Available environments are \"public\" or \"usgovernment\"."
  }
}

variable "location" {
  description = "Azure location to target."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to create resources in, some resources will be created in a separate AKS managed resource group."
  type        = string
}

variable "cluster_name" {
  description = "Name of the Azure Kubernetes Service managed cluster to create, also used as a prefix in names of related resources. This must be lowercase and contain the pattern \"aks-{ordinal}\"."
  type        = string

  validation {
    condition     = var.cluster_name == lower(var.cluster_name)
    error_message = "Cluster name should be lowercase."
  }

  validation {
    condition     = length(regexall("(?i)^(?:.+-)aks-\\d+", var.cluster_name)) > 0
    error_message = "Cluster name should contain a unique \"aks-<ordinal>\" component."
  }
}

variable "cluster_version" {
  description = "Kubernetes version to use for the Azure Kubernetes Service managed cluster, versions \"1.23\", \"1.22\" or \"1.21\" (DEPRECATED) are supported."
  type        = string

  validation {
    condition     = contains(["1.23", "1.22", "1.21"], var.cluster_version)
    error_message = "Available versions are \"1.23\", \"1.22\" or \"1.21\"."
  }
}

variable "network_plugin" {
  description = "Kubernetes network plugin, \"kubenet\" & \"azure\" are supported."
  type        = string
  default     = "kubenet"

  validation {
    condition     = contains(["kubenet", "azure"], var.network_plugin)
    error_message = "Available network plugin are \"kubenet\" or \"azure\"."
  }
}

variable "sku_tier_paid" {
  description = "If the cluster control plane SKU tier should be paid or free. The paid tier has a financially-backed uptime SLA."
  type        = bool
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Azure Kubernetes Service managed cluster public API server endpoint is enabled."
  type        = bool
}

variable "cluster_endpoint_access_cidrs" {
  description = "List of CIDR blocks which can access the Azure Kubernetes Service managed cluster API server endpoint, an empty list will not error but will block public access to the cluster."
  type        = list(string)

  validation {
    condition     = length(var.cluster_endpoint_access_cidrs) > 0
    error_message = "Cluster endpoint access CIDRS need to be explicitly set."
  }

  validation {
    condition     = alltrue([for c in var.cluster_endpoint_access_cidrs : can(regex("^(\\d{1,3}).(\\d{1,3}).(\\d{1,3}).(\\d{1,3})\\/(\\d{1,2})$", c))])
    error_message = "Cluster endpoint access CIDRS can only contain valid cidr blocks."
  }
}

variable "virtual_network_resource_group_name" {
  description = "Name of the resource group containing the virtual network."
  type        = string
}

variable "virtual_network_name" {
  description = "Name of the virtual network to use for the cluster."
  type        = string
}

variable "subnet_name" {
  description = "Name of the AKS subnet in the virtual network."
  type        = string
}

variable "route_table_name" {
  description = "Name of the AKS subnet route table."
  type        = string
}

variable "dns_resource_group_lookup" {
  description = "Lookup from DNS zone to resource group name."
  type        = map(string)
}

variable "podnet_cidr_block" {
  description = "CIDR range for pod IP addresses when using the kubenet network plugin, if you're running more than one cluster in a virtual network this value needs to be unique."
  type        = string
  default     = "100.65.0.0/16"
}

variable "managed_outbound_ip_count" {
  description = "Count of desired managed outbound IPs for the cluster load balancer. Must be between 1 and 100 inclusive."
  type        = number
  default     = 1

  validation {
    condition     = var.managed_outbound_ip_count > 0 && var.managed_outbound_ip_count <= 100
    error_message = "Managed outbound IP count must be between 1 and 100 inclusive."
  }
}

variable "admin_group_object_ids" {
  description = "AD Object IDs to be added to the cluster admin group, this should only ever be used to make the Terraform identity an admin if it can't be done outside the module."
  type        = list(string)
  default     = []
}

variable "azuread_clusterrole_map" {
  description = "Map of Azure AD user and group IDs to configure via Kubernetes ClusterRoleBindings."
  type = object({
    cluster_admin_users  = map(string)
    cluster_view_users   = map(string)
    standard_view_users  = map(string)
    standard_view_groups = map(string)
  })
  default = {
    cluster_admin_users  = {}
    cluster_view_users   = {}
    standard_view_users  = {}
    standard_view_groups = {}
  }
}

variable "node_group_templates" {
  description = "Templates describing the requires node groups."
  type = list(object({
    name                = string
    node_os             = string
    node_type           = string
    node_type_version   = string
    node_size           = string
    single_group        = bool
    min_capacity        = number
    max_capacity        = number
    placement_group_key = string
    labels              = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    tags = map(string)
  }))

  validation {
    condition     = alltrue([for x in var.node_group_templates : x.name != null && length(x.name) <= 10])
    error_message = "Node group template names must be 10 characters or less."
  }

  validation {
    condition     = alltrue([for x in var.node_group_templates : contains(["ubuntu", "windows"], x.node_os)])
    error_message = "Node group template OS must be either \"ubuntu\" or \"windows\"."
  }

  validation {
    condition     = alltrue([for x in var.node_group_templates : contains(["gp", "gpd", "mem", "memd", "cpu", "stor"], x.node_type)])
    error_message = "Node group template type must be one of \"gp\", \"gpd\", \"mem\", \"memd\", \"cpu\" or \"stor\"."
  }

  validation {
    condition     = alltrue([for x in var.node_group_templates : length(x.placement_group_key != null ? x.placement_group_key : "") <= 11])
    error_message = "Node group template placement key must be 11 characters or less."
  }
}

variable "core_services_config" {
  description = "Core service configuration."
  type        = any

  validation {
    condition     = lookup(var.core_services_config, "alertmanager", null) != null && length(lookup(var.core_services_config.alertmanager, "smtp_host", "")) > 0 && length(lookup(var.core_services_config.alertmanager, "smtp_from", "")) > 0
    error_message = "The core configuration variable for Alertmanager doesn't have all the required fields, please check the module README."
  }

  validation {
    condition     = lookup(var.core_services_config, "ingress_internal_core", null) != null && length(lookup(var.core_services_config.ingress_internal_core, "domain", "")) > 0
    error_message = "The core configuration variable for the internal ingress core doesn't have all the required fields, please check the module README."
  }
}

variable "control_plane_logging_external_workspace" {
  description = "If true, the log analytics workspace referenced in control_plane_logging_external_workspace_id will be used to store the logs. Otherwise a log analytics workspace will be created to store the logs."
  type        = bool
  default     = false
}

variable "control_plane_logging_external_workspace_id" {
  description = "ID of the log analytics workspace to send control plane logs to if control_plane_logging_external_workspace is true."
  type        = string
  default     = null
}

variable "control_plane_logging_external_workspace_different_resource_group" {
  description = "If true, the log analytics workspace referenced in control_plane_logging_external_workspace_id is created in a different resource group to the cluster."
  type        = bool
  default     = false
}

variable "control_plane_logging_workspace_categories" {
  description = "The control plane log categories to send to the log analytics workspace."
  type        = string
  default     = "recommended"
}

variable "control_plane_logging_workspace_retention_enabled" {
  description = "If true, the control plane logs being sent to log analytics will use the retention specified in control_plane_logging_workspace_retention_days otherwise the log analytics workspace default retention will be used."
  type        = bool
  default     = false
}

variable "control_plane_logging_workspace_retention_days" {
  description = "How long the logs should be retained by the log analytics workspace if control_plane_logging_workspace_retention_enabled is true, in days."
  type        = number
  default     = 0
}

variable "control_plane_logging_storage_account_enabled" {
  description = "If true, cluster control plane logs will be sent to the storage account referenced in control_plane_logging_storage_account_id as well as the default log analytics workspace."
  type        = bool
  default     = false
}

variable "control_plane_logging_storage_account_id" {
  description = "ID of the storage account to add cluster control plane logs to if control_plane_logging_storage_account_enabled is true. "
  type        = string
  default     = null
}

variable "control_plane_logging_storage_account_categories" {
  description = "The control plane log categories to send to the storage account."
  type        = string
  default     = "all"
}

variable "control_plane_logging_storage_account_retention_enabled" {
  description = "If true, the control plane logs being sent to the storage account will use the retention specified in control_plane_logging_storage_account_retention_days otherwise no retention will be set."
  type        = bool
  default     = true
}

variable "control_plane_logging_storage_account_retention_days" {
  description = "How long the logs should be retained by the storage account if control_plane_logging_storage_account_retention_enabled is true, in days."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "maintenance_window_offset" {
  description = "Maintenance window offset to utc."
  type        = number
  default     = null
}

variable "maintenance_window_allowed_days" {
  description = "List of allowed days covering the maintenance window."
  type        = list(string)
  default     = []
}

variable "maintenance_window_allowed_hours" {
  description = "List of allowed hours covering the maintenance window."
  type        = list(number)
  default     = []
}

variable "maintenance_window_not_allowed" {
  description = "Array of not allowed blocks including start and end times in rfc3339 format. A not allowed block takes priority if it overlaps an allowed blocks in a maintenance window."
  type = list(object({
    start = string
    end   = string
  }))
  default = []
}

# tflint-ignore: terraform_unused_declarations
variable "experimental" {
  description = "Configure experimental features."
  type        = any
  default     = {}
}
