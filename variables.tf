variable "azure_env" {
  description = "Azure cloud environment type, \"public\" & \"usgovernment\" are supported."
  type        = string
  nullable    = false
  default     = "public"

  validation {
    condition     = contains(["public", "usgovernment"], var.azure_env)
    error_message = "Available environments are \"public\" or \"usgovernment\"."
  }
}

variable "location" {
  description = "Azure location to target."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "Name of the resource group to create resources in, some resources will be created in a separate AKS managed resource group."
  type        = string
  nullable    = false
}

variable "cluster_name" {
  description = "Name of the Azure Kubernetes Service managed cluster to create, also used as a prefix in names of related resources. This must be lowercase and contain the pattern \"aks-{ordinal}\"."
  type        = string
  nullable    = false

  validation {
    condition     = var.cluster_name == lower(var.cluster_name)
    error_message = "Cluster name should be lowercase."
  }

  validation {
    condition     = length(regexall("(?i)^(?:.+-)aks-\\d+", var.cluster_name)) > 0
    error_message = "Kubernetes Service managed cluster to create, also used as a prefix in names of related resources. This must be lowercase and contain the pattern `aks-{ordinal}` (e.g. `app-aks-0` or `app-aks-1`)."
  }
}

variable "cluster_version" {
  description = "Kubernetes version to use for the Azure Kubernetes Service managed cluster; versions \"1.24\" (EXPERIMENTAL), \"1.23\" or \"1.22\" (DEPRECATED) are supported."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["1.24", "1.23", "1.22"], var.cluster_version)
    error_message = "Available versions are \"1.24\", \"1.23\" or \"1.22\"."
  }
}

variable "network_plugin" {
  description = "Kubernetes network plugin, \"kubenet\" & \"azure\" are supported."
  type        = string
  nullable    = false
  default     = "kubenet"

  validation {
    condition     = contains(["kubenet", "azure"], var.network_plugin)
    error_message = "Available network plugin are \"kubenet\" or \"azure\"."
  }
}

variable "sku_tier_paid" {
  description = "If the cluster control plane SKU tier should be paid or free. The paid tier has a financially-backed uptime SLA."
  type        = bool
  nullable    = false
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Azure Kubernetes Service managed cluster public API server endpoint is enabled."
  type        = bool
  nullable    = false
}

variable "cluster_endpoint_access_cidrs" {
  description = "List of CIDR blocks which can access the Azure Kubernetes Service managed cluster API server endpoint, an empty list will not error but will block public access to the cluster."
  type        = list(string)
  nullable    = false

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
  nullable    = false
}

variable "virtual_network_name" {
  description = "Name of the virtual network to use for the cluster."
  type        = string
  nullable    = false
}

variable "subnet_name" {
  description = "Name of the AKS subnet in the virtual network."
  type        = string
  nullable    = false
}

variable "route_table_name" {
  description = "Name of the AKS subnet route table."
  type        = string
  nullable    = false
}

variable "dns_resource_group_lookup" {
  description = "Lookup from DNS zone to resource group name."
  type        = map(string)
  nullable    = false
}

variable "podnet_cidr_block" {
  description = "CIDR range for pod IP addresses when using the kubenet network plugin, if you're running more than one cluster in a virtual network this value needs to be unique."
  type        = string
  nullable    = false
  default     = "100.65.0.0/16"
}

variable "nat_gateway_id" {
  description = "ID of a user-assigned NAT Gateway to use for cluster egress traffic, if not set a cluster managed load balancer will be used."
  type        = string
  nullable    = true
  default     = null
}

variable "managed_outbound_ip_count" {
  description = "Count of desired managed outbound IPs for the cluster managed load balancer. Ignored if NAT gateway is specified, must be between 1 and 100 inclusive."
  type        = number
  nullable    = false
  default     = 1

  validation {
    condition     = var.managed_outbound_ip_count > 0 && var.managed_outbound_ip_count <= 100
    error_message = "Managed outbound IP count must be between 1 and 100 inclusive."
  }
}

variable "managed_outbound_ports_allocated" {
  description = "Number of desired SNAT port for each VM in the cluster managed load balancer. Ignored if NAT gateway is specified, must be between 0 & 64000 inclusive and divisible by 8."
  type        = number
  nullable    = false
  default     = 0

  validation {
    condition     = var.managed_outbound_ports_allocated >= 0 && var.managed_outbound_ports_allocated <= 64000 && (var.managed_outbound_ports_allocated % 8 == 0)
    error_message = "Number of desired SNAT port for each VM must be between 0 & 64000 inclusive and divisible by 8."
  }
}

variable "managed_outbound_idle_timeout" {
  description = "Desired outbound flow idle timeout in seconds for the cluster managed load balancer. Ignored if NAT gateway is specified, must be between 240 and 7200 inclusive."
  type        = number
  nullable    = false
  default     = 240

  validation {
    condition     = var.managed_outbound_idle_timeout >= 240 && var.managed_outbound_idle_timeout <= 7200
    error_message = "Outbound flow idle timeout must be between 240 and 7200 inclusive."
  }
}

variable "admin_group_object_ids" {
  description = "AD Object IDs to be added to the cluster admin group, this should only ever be used to make the Terraform identity an admin if it can't be done outside the module."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "rbac_bindings" {
  description = "User and groups to configure in Kubernetes ClusterRoleBindings; for Azure AD these are the IDs."
  type = object({
    cluster_admin_users = optional(map(any))
    cluster_view_users  = optional(map(any))
    cluster_view_groups = optional(list(string))
  })
  nullable = false
  default  = {}
}

variable "node_groups" {
  description = "Node groups to configure."
  type = map(object({
    node_arch           = optional(string)
    node_os             = optional(string)
    node_type           = optional(string)
    node_type_version   = optional(string)
    node_size           = string
    single_group        = optional(bool)
    min_capacity        = optional(number)
    max_capacity        = number
    os_config           = optional(map(any))
    ultra_ssd           = optional(bool)
    placement_group_key = optional(string)
    max_pods            = optional(number)
    labels              = optional(map(string))
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })))
    tags = optional(map(string))
  }))
  nullable = false
  default  = {}
}

variable "core_services_config" {
  description = "Core service configuration."
  type = object({
    alertmanager = object({
      smtp_host = string
      smtp_from = string
      receivers = optional(list(object({
        name              = string
        email_configs     = optional(any, [])
        opsgenie_configs  = optional(any, [])
        pagerduty_configs = optional(any, [])
        pushover_configs  = optional(any, [])
        slack_configs     = optional(any, [])
        sns_configs       = optional(any, [])
        victorops_configs = optional(any, [])
        webhook_configs   = optional(any, [])
        wechat_configs    = optional(any, [])
        telegram_configs  = optional(any, [])
      })))
      routes = optional(list(object({
        receiver            = string
        group_by            = optional(list(string))
        continue            = optional(bool)
        matchers            = list(string)
        group_wait          = optional(string)
        group_interval      = optional(string)
        repeat_interval     = optional(string)
        mute_time_intervals = optional(list(string))
        # active_time_intervals = optional(list(string))
      })))
    })
    cert_manager = optional(object({
      acme_dns_zones      = optional(list(string))
      additional_issuers  = optional(map(any))
      default_issuer_kind = optional(string)
      default_issuer_name = optional(string)
    }))
    coredns = optional(object({
      forward_zones = optional(map(any))
    }))
    external_dns = optional(object({
      additional_sources     = optional(list(string))
      private_domain_filters = optional(list(string))
      public_domain_filters  = optional(list(string))
    }))
    fluentd = optional(object({
      image_repository = optional(string)
      image_tag        = optional(string)
      additional_env   = optional(map(string))
      debug            = optional(bool)
      filters          = optional(string)
      route_config = optional(list(object({
        match  = string
        label  = string
        copy   = optional(bool)
        config = string
      })))
      routes  = optional(string)
      outputs = optional(string)
    }))
    grafana = optional(object({
      admin_password          = optional(string)
      additional_plugins      = optional(list(string))
      additional_data_sources = optional(list(any))
    }))
    ingress_internal_core = optional(object({
      domain           = string
      subdomain_suffix = optional(string)
      lb_source_cidrs  = optional(list(string))
      lb_subnet_name   = optional(string)
      public_dns       = optional(bool)
    }))
    prometheus = optional(object({
      remote_write = optional(any)
    }))
  })
  nullable = false
}

variable "control_plane_logging_external_workspace" {
  description = "If true, the log analytics workspace referenced in control_plane_logging_external_workspace_id will be used to store the logs. Otherwise a log analytics workspace will be created to store the logs."
  type        = bool
  nullable    = false
  default     = false
}

variable "control_plane_logging_external_workspace_id" {
  description = "ID of the log analytics workspace to send control plane logs to if control_plane_logging_external_workspace is true."
  type        = string
  nullable    = true
  default     = null
}

variable "control_plane_logging_external_workspace_different_resource_group" {
  description = "If true, the log analytics workspace referenced in control_plane_logging_external_workspace_id is created in a different resource group to the cluster."
  type        = bool
  nullable    = false
  default     = false
}

variable "control_plane_logging_workspace_categories" {
  description = "The control plane log categories to send to the log analytics workspace."
  type        = string
  nullable    = false
  default     = "recommended"
}

variable "control_plane_logging_workspace_retention_enabled" {
  description = "If true, the control plane logs being sent to log analytics will use the retention specified in control_plane_logging_workspace_retention_days otherwise the log analytics workspace default retention will be used."
  type        = bool
  nullable    = false
  default     = false
}

variable "control_plane_logging_workspace_retention_days" {
  description = "How long the logs should be retained by the log analytics workspace if control_plane_logging_workspace_retention_enabled is true, in days."
  type        = number
  nullable    = false
  default     = 0
}

variable "control_plane_logging_storage_account_enabled" {
  description = "If true, cluster control plane logs will be sent to the storage account referenced in control_plane_logging_storage_account_id as well as the default log analytics workspace."
  type        = bool
  nullable    = false
  default     = false
}

variable "control_plane_logging_storage_account_id" {
  description = "ID of the storage account to add cluster control plane logs to if control_plane_logging_storage_account_enabled is true. "
  type        = string
  nullable    = true
  default     = null
}

variable "control_plane_logging_storage_account_categories" {
  description = "The control plane log categories to send to the storage account."
  type        = string
  nullable    = false
  default     = "all"
}

variable "control_plane_logging_storage_account_retention_enabled" {
  description = "If true, the control plane logs being sent to the storage account will use the retention specified in control_plane_logging_storage_account_retention_days otherwise no retention will be set."
  type        = bool
  nullable    = false
  default     = true
}

variable "control_plane_logging_storage_account_retention_days" {
  description = "How long the logs should be retained by the storage account if control_plane_logging_storage_account_retention_enabled is true, in days."
  type        = number
  nullable    = false
  default     = 30
}

variable "maintenance_window_offset" {
  description = "Maintenance window offset to utc."
  type        = number
  nullable    = true
  default     = null
}

variable "maintenance_window_allowed_days" {
  description = "List of allowed days covering the maintenance window."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "maintenance_window_allowed_hours" {
  description = "List of allowed hours covering the maintenance window."
  type        = list(number)
  nullable    = false
  default     = []
}

variable "maintenance_window_not_allowed" {
  description = "Array of not allowed blocks including start and end times in rfc3339 format. A not allowed block takes priority if it overlaps an allowed blocks in a maintenance window."
  type = list(object({
    start = string
    end   = string
  }))
  nullable = false
  default  = []
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "experimental" {
  description = "Configure experimental features."
  type = object({
    fips                                                       = optional(bool, false)
    oms_agent                                                  = optional(bool, false)
    oms_agent_log_analytics_workspace_different_resource_group = optional(bool, false)
    oms_agent_log_analytics_workspace_id                       = optional(string, null)
    oms_agent_create_configmap                                 = optional(bool, true)
    windows_support                                            = optional(bool, false)
    v1_24                                                      = optional(bool, false)
    arm64                                                      = optional(bool, false)
    node_group_os_config                                       = optional(bool, false)
    azure_cni_max_pods                                         = optional(bool, false)
    aad_pod_identity_finalizer_wait                            = optional(string, null)
    fluent_bit_use_memory_buffer                               = optional(bool, false)
    fluentd_memory_override                                    = optional(string, null)
    prometheus_memory_override                                 = optional(string, null)
  })
  nullable = false
  default  = {}
}
