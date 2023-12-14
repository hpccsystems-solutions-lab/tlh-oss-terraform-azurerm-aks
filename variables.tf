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
  description = "Kubernetes version to use for the Azure Kubernetes Service managed cluster; versions \"1.27\" 1.26\" or \"1.25\" are supported."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["1.27", "1.26", "1.25"], var.cluster_version)
    error_message = "Available versions are \"1.27\", \"1.26\" or \"1.25\""
  }
}

variable "sku_tier" {
  description = "Pricing tier for the Azure Kubernetes Service managed cluster; \"FREE\" & \"STANDARD\" are supported. For production clusters or clusters with more than 10 nodes this should be set to \"STANDARD\"."
  type        = string
  nullable    = false
  default     = "FREE"

  validation {
    condition     = contains(["FREE", "STANDARD"], var.sku_tier)
    error_message = "Available SKU tiers are \"FREE\" or \"STANDARD\"."
  }
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

variable "system_nodes" {
  description = "System node group to configure."
  type = object({
    node_arch         = optional(string, "amd64")
    #node_size         = optional(string, "xlarge")
    node_size         = optional(string, "large")
    node_type_version = optional(string, "v1")
    min_capacity      = optional(number, 1)
  })
  nullable = false
  default  = {}

  validation {
    condition     = contains(["amd64", "arm64"], var.system_nodes.node_arch)
    error_message = "Node group architecture must be either \"amd64\" or \"arm64\"."
  }

  validation {
    condition     = (var.system_nodes.min_capacity > 0)
    error_message = "System node group min capacity must be 0 or more."
  }
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
    max_pods            = optional(number, null)
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

  validation {
    condition     = alltrue([for k, v in var.node_groups : length(k) <= 10])
    error_message = "Node group names must be 10 characters or less."
  }

  validation {
    condition     = alltrue([for k, v in var.node_groups : contains(["amd64", "arm64"], v.node_arch)])
    error_message = "Node group architecture must be either \"amd64\" or \"arm64\"."
  }

  validation {
    condition     = alltrue([for k, v in var.node_groups : contains(["ubuntu", "windows2019", "windows2022"], v.node_os)])
    error_message = "Node group OS must be one of \"ubuntu\", \"windows2019\" (UNSUPPORTED) or \"windows2022\" (EXPERIMENTAL)."
  }

  validation {
    condition     = alltrue([for k, v in var.node_groups : contains(["gp", "gpd", "mem", "memd", "cpu", "stor"], v.node_type)])
    error_message = "Node group type must be one of \"gp\", \"gpd\", \"mem\", \"memd\", \"cpu\" or \"stor\"."
  }

  validation {
    condition     = alltrue([for k, v in var.node_groups : contains(["NONE", "KUBELET", "HOST_PATH"], v.temp_disk_mode)])
    error_message = "Temp disk mode must be one of \"NONE\", \"KUBELET\", \"HOST_PATH\"."
  }

  validation {
    condition     = alltrue([for k, v in var.node_groups : contains(["NONE", "PV", "HOST_PATH"], v.nvme_mode)])
    error_message = "NVMe mode must be one of \"NONE\", \"PV\", \"HOST_PATH\"."
  }

  validation {
    condition     = alltrue([for k, v in var.node_groups : length(coalesce(v.placement_group_key, "_")) <= 11])
    error_message = "Node group placement key must be 11 characters or less."
  }

  validation {
    condition     = alltrue([for k, v in var.node_groups : v.max_pods == null || (coalesce(v.max_pods, 110) >= 12 && coalesce(v.max_pods, 110) <= 110)])
    error_message = "Node group max pods must either be null or between 12 & 110."
  }

  validation {
    condition     = alltrue([for k, v in var.node_groups : can(tonumber(replace(v.max_surge, "%", "")))])
    error_message = "Node group max surge must either be a number or a percent; e.g. 1 or 10%."
  }
}

variable "logging" {
  description = "Logging configuration."
  type = object({
    control_plane = object({
      log_analytics = optional(object({
        enabled                       = optional(bool, false)
        workspace_id                  = optional(string, null)
        profile                       = optional(string, "audit-write-only")
        additional_log_category_types = optional(list(string), [])
      }), {})

      storage_account = optional(object({
        enabled                       = optional(bool, false)
        id                            = optional(string, null)
        profile                       = optional(string, "all")
        additional_log_category_types = optional(list(string), [])
        retention_enabled             = optional(bool, true)
        retention_days                = optional(number, 30)
      }), {})
    })

    nodes = optional(object({
      storage_account = optional(object({
        enabled     = optional(bool, false)
        id          = optional(string, null)
        container   = optional(string, "nodes")
        path_prefix = optional(string, null)
      }), {})
      loki = optional(object({
        enabled = optional(bool, false)
      }), {})
    }), {})

    workloads = optional(object({
      core_service_log_level = optional(string, "WARN")

      storage_account = optional(object({
        enabled     = optional(bool, false)
        id          = optional(string, null)
        container   = optional(string, "workloads")
        path_prefix = optional(string, null)
      }), {})

      loki = optional(object({
        enabled = optional(bool, false)
      }), {})

    }), {})

    log_analytics_workspace_config = optional(object({
      id = optional(string, null)
    }), {})

    storage_account_config = optional(object({
      id = optional(string, null)
    }), {})

    extra_records = optional(map(string), {})
  })
  nullable = false

  /*validation {
    condition     = var.logging.control_plane.log_analytics.enabled || var.logging.control_plane.storage_account.enabled
    error_message = "Control plane logging must be enabled."
  }*/

  validation {
    condition     = !var.logging.control_plane.log_analytics.enabled || var.logging.control_plane.log_analytics.workspace_id != null || var.logging.log_analytics_workspace_config.id != null
    error_message = "Control plane logging to a log analytics workspace requires a workspace ID."
  }

  validation {
    condition     = !var.logging.control_plane.log_analytics.enabled || (var.logging.control_plane.log_analytics.profile != null && contains(["all", "audit-write-only", "minimal", "empty"], coalesce(var.logging.control_plane.log_analytics.profile, "empty")))
    error_message = "Control plane logging to a log analytics external workspace requires a profile."
  }

  validation {
    condition     = !var.logging.control_plane.storage_account.enabled || var.logging.control_plane.storage_account.id != null || var.logging.storage_account_config.id != null
    error_message = "Control plane logging to a storage account requires an ID."
  }

  validation {
    condition     = !var.logging.control_plane.storage_account.enabled || (var.logging.control_plane.storage_account.profile != null && contains(["all", "audit-write-only", "minimal", "empty"], coalesce(var.logging.control_plane.storage_account.profile, "empty")))
    error_message = "Control plane logging to a storage account requires profile."
  }

  validation {
    condition     = !var.logging.nodes.storage_account.enabled || var.logging.nodes.storage_account.id != null || var.logging.storage_account_config.id != null
    error_message = "Nodes logging to a storage account requires an ID."
  }

  validation {
    condition     = !var.logging.workloads.storage_account.enabled || var.logging.workloads.storage_account.id != null || var.logging.storage_account_config.id != null
    error_message = "Workloads logging to a storage account requires an ID."
  }
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
      resource_overrides = optional(map(object({
        cpu       = optional(number, null)
        cpu_limit = optional(number, null)
        memory    = optional(number, null)
      })), {})
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
      resource_overrides = optional(map(object({
        cpu       = optional(number, null)
        cpu_limit = optional(number, null)
        memory    = optional(number, null)
      })), {})
    }), {})
    grafana = optional(object({
      admin_password          = optional(string, "changeme")
      additional_plugins      = optional(list(string), [])
      additional_data_sources = optional(any, [])
      resource_overrides = optional(map(object({
        cpu       = optional(number, null)
        cpu_limit = optional(number, null)
        memory    = optional(number, null)
      })), {})
    }), {})
    ingress_internal_core = object({
      domain           = string
      subdomain_suffix = optional(string, null)
      lb_source_cidrs  = optional(list(string), ["10.0.0.0/8", "100.65.0.0/16"])
      lb_subnet_name   = optional(string, null)
      public_dns       = optional(bool, false)
    })
    kube_state_metrics = optional(object({
      resource_overrides = optional(map(object({
        cpu       = optional(number, null)
        cpu_limit = optional(number, null)
        memory    = optional(number, null)
      })), {})
    }), {})
    prometheus = optional(object({
      remote_write = optional(any, [])
      resource_overrides = optional(map(object({
        cpu       = optional(number, null)
        cpu_limit = optional(number, null)
        memory    = optional(number, null)
      })), {})
    }), {})
    prometheus_node_exporter = optional(object({
      resource_overrides = optional(map(object({
        cpu       = optional(number, null)
        cpu_limit = optional(number, null)
        memory    = optional(number, null)
      })), {})
    }), {})
    thanos = optional(object({
      resource_overrides = optional(map(object({
        cpu       = optional(number, null)
        cpu_limit = optional(number, null)
        memory    = optional(number, null)
      })), {})
    }), {})
    loki = optional(object({
      resource_overrides = optional(map(object({
        cpu       = optional(number, null)
        cpu_limit = optional(number, null)
        memory    = optional(number, null)
      })), {})
    }), {})
  })
  nullable = false
}

variable "maintenance" {
  description = "Maintenance configuration."
  type = object({
    utc_offset = optional(string, null)
    control_plane = optional(object({
      frequency    = optional(string, "WEEKLY")
      day_of_month = optional(number, 1)
      day_of_week  = optional(string, "SUNDAY")
      start_time   = optional(string, "00:00")
      duration     = optional(number, 4)
    }), {})
    nodes = optional(object({
      frequency    = optional(string, "WEEKLY")
      day_of_month = optional(number, 1)
      day_of_week  = optional(string, "SUNDAY")
      start_time   = optional(string, "00:00")
      duration     = optional(number, 4)
    }), {})
    not_allowed = optional(list(object({
      start = string
      end   = string
    })), [])
  })
  nullable = false
  default  = {}

  validation {
    condition     = contains(["WEEKLY", "FORTNIGHTLY", "MONTHLY"], var.maintenance.control_plane.frequency)
    error_message = "Control plane maintainance frequency must be one of \"WEEKLY\", \"FORTNIGHTLY\" or \"MONTHLY\"."
  }

  validation {
    condition     = contains(["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"], var.maintenance.control_plane.day_of_week)
    error_message = "Control plane maintainance day of week must be one of \"MONDAY\", \"TUESDAY\", \"WEDNESDAY\", \"THURSDAY\", \"FRIDAY\", \"SATURDAY\" or \"SUNDAY\"."
  }

  validation {
    condition     = var.maintenance.control_plane.day_of_month >= 1 && var.maintenance.control_plane.day_of_month <= 28
    error_message = "Control plane maintainance day of month must be between 1 & 28."
  }

  validation {
    condition     = var.maintenance.control_plane.duration >= 4
    error_message = "Control plane maintainance duration must be 4 hours or more."
  }

  validation {
    condition     = contains(["DAILY", "WEEKLY", "FORTNIGHTLY", "MONTHLY"], var.maintenance.nodes.frequency)
    error_message = "Node maintainance frequency must be one of \"DAILY\", \"WEEKLY\", \"FORTNIGHTLY\" or \"MONTHLY\"."
  }

  validation {
    condition     = contains(["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"], var.maintenance.nodes.day_of_week)
    error_message = "Node maintainance day of week must be one of \"MONDAY\", \"TUESDAY\", \"WEDNESDAY\", \"THURSDAY\", \"FRIDAY\", \"SATURDAY\" or \"SUNDAY\"."
  }

  validation {
    condition     = var.maintenance.nodes.day_of_month >= 1 && var.maintenance.control_plane.day_of_month <= 28
    error_message = "Node maintainance day of month must be between 1 & 28."
  }

  validation {
    condition     = var.maintenance.nodes.duration >= 4
    error_message = "Node maintainance duration must be 4 hours or more."
  }
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

variable "logging_monitoring_enabled" {
  description = "If true then logging and monitoring will occur else it will not."
  type        = bool
  nullable    = false
  default     = true
}

variable "experimental" {
  description = "Configure experimental features."
  type = object({
    oms_agent                               = optional(bool, false)
    oms_agent_log_analytics_workspace_id    = optional(string, null)
    oms_agent_create_configmap              = optional(bool, true)
    oms_agent_containerlog_schema_version   = optional(string, "v1")
    windows_support                         = optional(bool, false)
    arm64                                   = optional(bool, false)
    node_group_os_config                    = optional(bool, false)
    azure_cni_max_pods                      = optional(bool, false)
    aad_pod_identity_finalizer_wait         = optional(string, null)
    fluent_bit_use_memory_buffer            = optional(bool, false)
    fluent_bit_aggregator                   = optional(bool, false)
    fluent_bit_aggregator_replicas_per_zone = optional(number, 1)
    fluent_bit_aggregator_extra_env         = optional(map(string), {})
    fluent_bit_aggregator_secret_env        = optional(map(string), {})
    fluent_bit_aggregator_lua_scripts       = optional(map(string), {})
    fluent_bit_aggregator_raw_filters       = optional(string, null)
    fluent_bit_aggregator_raw_outputs       = optional(string, null)
    fluent_bit_aggregator_resource_overrides = optional(map(object({
      cpu       = optional(number, null)
      cpu_limit = optional(number, null)
      memory    = optional(number, null)
    })), {})
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
    fluent_bit_collector_parsers = optional(map(object({
      pattern = string
      types   = optional(map(string), {})
    })), {})
    azure_cni_overlay = optional(bool, false)
  })
  nullable = false
  default  = {}
}

variable "availability_zones" {
  description = "Availability zones to use for the node groups."
  type        = list(number)
  nullable    = false
  default     = [1]
}
