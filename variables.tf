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
  description = "Kubernetes version to use for the Azure Kubernetes Service managed cluster; versions \"1.26\", \"1.25\" or \"1.24\" are supported."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["1.26", "1.25", "1.24"], var.cluster_version)
    error_message = "Available versions are \"1.26\", \"1.25\" or \"1.24\""
  }
}

variable "sku_tier" {
  description = "Pricing tier for the Azure Kubernetes Service managed cluster; \"free\" & \"standard\" are supported. For production clusters or clusters with more than 10 nodes this should be set to \"standard\"."
  type        = string
  nullable    = false
  default     = "free"

  validation {
    condition     = contains(["free", "standard"], var.sku_tier)
    error_message = "Available SKU tiers are \"free\" or \"standard\"."
  }
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
    cluster_admin_users = optional(map(any), {})
    cluster_view_users  = optional(map(any), {})
    cluster_view_groups = optional(list(string), [])
  })
  nullable = false
  default  = {}
}

variable "node_groups" {
  description = "Node groups to configure."
  type = map(object({
    node_arch           = optional(string, "amd64")
    node_os             = optional(string, "ubuntu")
    node_type           = optional(string, "gp")
    node_type_variant   = optional(string, "default")
    node_type_version   = optional(string, "v1")
    node_size           = string
    ultra_ssd           = optional(bool, false)
    os_disk_size        = optional(number, 128)
    temp_disk_mode      = optional(string, "NONE")
    nvme_mode           = optional(string, "NONE")
    placement_group_key = optional(string, null)
    single_group        = optional(bool, false)
    min_capacity        = optional(number, 0)
    max_capacity        = number
    max_pods            = optional(number, -1)
    max_surge           = optional(string, "10%")
    labels              = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
    os_config = optional(object({
      sysctl = optional(map(any), {})
    }), {})
    tags = optional(map(string), {})
  }))
  nullable = false
  default  = {}
}

variable "logging" {
  description = "Logging configuration."
  type = object({
    control_plane = optional(object({
      log_analytics = optional(object({
        enabled                       = optional(bool, true)
        external_workspace            = optional(bool, false)
        workspace_id                  = optional(string, null)
        profile                       = optional(string, "audit-write-only")
        additional_log_category_types = optional(list(string), [])
        retention_enabled             = optional(bool, true)
        retention_days                = optional(number, 30)
      }), {})
      storage_account = optional(object({
        enabled                       = optional(bool, false)
        id                            = optional(string, null)
        profile                       = optional(string, "all")
        additional_log_category_types = optional(list(string), [])
        retention_enabled             = optional(bool, true)
        retention_days                = optional(number, 30)
      }), {})
    }), {})

    workloads = optional(object({
      core_service_log_level      = optional(string, "WARN")
      storage_account_logs        = optional(bool, false)
      storage_account_container   = optional(string, "workload")
      storage_account_path_prefix = optional(string, null)
    }), {})
    storage_account_config = optional(object({
      id = optional(string)
    }), {})

    extra_records = optional(map(string), {})
  })
  nullable = false
  default  = {}
}

variable "storage" {
  description = "Storage configuration."
  type = object({
    file = optional(object({
      enabled = optional(bool, false)
    }), {})
    blob = optional(object({
      enabled = optional(bool, false)
    }), {})
    nvme_pv = optional(object({
      enabled = optional(bool, false)
    }), {})
    host_path = optional(object({
      enabled = optional(bool, false)
    }), {})
  })
  nullable = false
  default  = {}
}

variable "core_services_config" {
  description = "Core service configuration."
  type = object({
    alertmanager = optional(object({
      smtp_host = optional(string, null)
      smtp_from = optional(string, null)
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
        group_by            = optional(list(string), [])
        continue            = optional(bool, false)
        matchers            = list(string)
        group_wait          = optional(string, "30s")
        group_interval      = optional(string, "5m")
        repeat_interval     = optional(string, "12h")
        mute_time_intervals = optional(list(string), [])
        # active_time_intervals = optional(list(string), [])
      })))
    }), {})
    cert_manager = optional(object({
      acme_dns_zones      = optional(list(string), [])
      additional_issuers  = optional(map(any), {})
      default_issuer_kind = optional(string, "ClusterIssuer")
      default_issuer_name = optional(string, "letsencrypt-staging")
    }), {})
    coredns = optional(object({
      forward_zones = optional(map(any), {})
    }), {})
    external_dns = optional(object({
      additional_sources     = optional(list(string), [])
      private_domain_filters = optional(list(string), [])
      public_domain_filters  = optional(list(string), [])
    }), {})
    fluentd = optional(object({
      image_repository = optional(string, null)
      image_tag        = optional(string, null)
      additional_env   = optional(map(string), {})
      debug            = optional(bool, false)
      filters          = optional(string, null)
      route_config = optional(list(object({
        match  = string
        label  = string
        copy   = optional(bool, false)
        config = string
      })), [])
    }), {})
    grafana = optional(object({
      admin_password          = optional(string, "changeme")
      additional_plugins      = optional(list(string), [])
      additional_data_sources = optional(any, [])
    }), {})
    ingress_internal_core = object({
      domain           = string
      subdomain_suffix = optional(string, null)
      lb_source_cidrs  = optional(list(string), ["10.0.0.0/8", "100.65.0.0/16"])
      lb_subnet_name   = optional(string, null)
      public_dns       = optional(bool, false)
    })
    prometheus = optional(object({
      remote_write = optional(any, [])
    }), {})
  })
  nullable = false
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

variable "fips" {
  description = "If true, the cluster will be created with FIPS 140-2 mode enabled; this can't be changed once the cluster has been created."
  type        = bool
  nullable    = false
  default     = false
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
    oms_agent                                   = optional(bool, false)
    oms_agent_log_analytics_workspace_id        = optional(string, null)
    oms_agent_create_configmap                  = optional(bool, true)
    oms_agent_containerlog_schema_version       = optional(string, "v1")
    windows_support                             = optional(bool, false)
    arm64                                       = optional(bool, false)
    node_group_os_config                        = optional(bool, false)
    azure_cni_max_pods                          = optional(bool, false)
    aad_pod_identity_finalizer_wait             = optional(string, null)
    fluent_bit_use_memory_buffer                = optional(bool, false)
    fluentd_memory_override                     = optional(string, null)
    prometheus_memory_override                  = optional(string, null)
    loki                                        = optional(bool, false)
    systemd_logs_loki                           = optional(bool, false)
    fluent_bit_aggregator                       = optional(bool, false)
    fluent_bit_aggregator_cpu_requests_override = optional(string, null)
    fluent_bit_aggregator_cpu_limits_override   = optional(string, null)
    fluent_bit_aggregator_memory_override       = optional(string, null)
    fluent_bit_aggregator_replicas_per_zone     = optional(number, 1)
    fluent_bit_aggregator_cpu_requests_override = optional(string, null)
    fluent_bit_aggregator_cpu_limits_override   = optional(string, null)
    fluent_bit_aggregator_memory_override       = optional(string, null)
    fluent_bit_aggregator_extra_env             = optional(map(string), {})
    fluent_bit_aggregator_secret_env            = optional(map(string), {})
    fluent_bit_aggregator_lua_scripts           = optional(map(string), {})
    fluent_bit_aggregator_raw_filters           = optional(string, null)
    fluent_bit_aggregator_raw_outputs           = optional(string, null)
    cluster_patch_upgrade                       = optional(bool, false)
    fluent_bit_collector_multiline_parsers = optional(map(object({
      rules = list(object({
        name           = string
        pattern        = string
        next_rule_name = string
      }))
      workloads = list(object({
        namespace  = string
        pod_prefix = string
      }))
    })), {})
  })
  nullable = false
  default  = {}
}
