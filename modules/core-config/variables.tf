variable "azure_env" {
  description = "Azure cloud environment type."
  type        = string
  nullable    = false
}

variable "tenant_id" {
  description = "ID of the Azure Tenant."
  type        = string
  nullable    = false
}

variable "subscription_id" {
  description = "ID of the subscription."
  type        = string
  nullable    = false
}

variable "location" {
  description = "Azure region in which the AKS cluster is located."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "Name of the resource group containing the AKS cluster."
  type        = string
  nullable    = false
}

variable "cluster_name" {
  description = "Name of the Azure Kubernetes managed cluster."
  type        = string
  nullable    = false
}

variable "cluster_version" {
  description = "Kubernetes version of the AKS cluster."
  type        = string
  nullable    = false
}

variable "cluster_oidc_issuer_url" {
  description = "The URL of the cluster OIDC issuer."
  type        = string
}

variable "cni" {
  description = "Kubernetes CNI."
  type        = string
  nullable    = false
}

variable "ingress_node_group" {
  description = "If an ingress node group is provisioned."
  type        = bool
  nullable    = false
}

variable "subnet_id" {
  description = "ID of the subnet."
  type        = string
  nullable    = false
}

variable "availability_zones" {
  description = "Availability zones to use for the node groups."
  type        = list(number)
  nullable    = false
}

variable "kubelet_identity_id" {
  description = "ID of the Kubelet identity."
  type        = string
  nullable    = false
}

variable "node_resource_group_name" {
  description = "Name of the node resource group."
  type        = string
  nullable    = false
}

variable "dns_resource_group_lookup" {
  description = "Lookup from DNS zone to resource group name."
  type        = map(string)
  nullable    = false
}

variable "logging" {
  description = "Logging configuration."
  type = object({
    control_plane = object({
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
        profile                       = string
        additional_log_category_types = list(string)
        retention_enabled             = bool
        retention_days                = number
      })
    })

    workloads = object({
      core_service_log_level      = string
      storage_account_logs        = bool
      storage_account_container   = string
      storage_account_path_prefix = string
    })
    storage_account_config = object({
      id = string
    })

    extra_records = map(string)
  })
  nullable = false
}

variable "storage" {
  description = "Storage configuration."
  type = object({
    file = object({
      enabled = bool
    })
    blob = object({
      enabled = bool
    })
    nvme_pv = object({
      enabled = bool
    })
    host_path = object({
      enabled = bool
    })
  })
  nullable = false
}

variable "core_services_config" {
  description = "Core service configuration."
  type = object({
    alertmanager = object({
      smtp_host = string
      smtp_from = string
      receivers = list(object({
        name              = string
        email_configs     = any
        opsgenie_configs  = any
        pagerduty_configs = any
        pushover_configs  = any
        slack_configs     = any
        sns_configs       = any
        victorops_configs = any
        webhook_configs   = any
        wechat_configs    = any
        telegram_configs  = any
      }))
      routes = list(object({
        receiver            = string
        group_by            = list(string)
        continue            = bool
        matchers            = list(string)
        group_wait          = string
        group_interval      = string
        repeat_interval     = string
        mute_time_intervals = list(string)
        # active_time_intervals = list(string)
      }))
    })
    cert_manager = object({
      acme_dns_zones      = list(string)
      additional_issuers  = map(any)
      default_issuer_kind = string
      default_issuer_name = string
    })
    coredns = object({
      forward_zones = map(any)
    })
    external_dns = object({
      additional_sources     = list(string)
      private_domain_filters = list(string)
      public_domain_filters  = list(string)
    })
    fluent_bit_aggregator = object({
      enabled           = bool
      replicas_per_zone = number
      extra_env         = map(string)
      secret_env        = map(string)
      lua_scripts       = map(string)
      raw_filters       = string
      raw_outputs       = string
    })
    fluentd = object({
      image_repository = string
      image_tag        = string
      additional_env   = map(string)
      debug            = bool
      filters          = string
      route_config = list(object({
        match  = string
        label  = string
        copy   = bool
        config = string
      }))
    })
    grafana = object({
      admin_password          = string
      additional_plugins      = list(string)
      additional_data_sources = list(any)
    })
    ingress_internal_core = object({
      domain           = string
      subdomain_suffix = string
      lb_source_cidrs  = list(string)
      lb_subnet_name   = string
      public_dns       = bool
    })
    loki = object({
      enabled   = bool
      node_logs = bool
    })
    oms_agent = object({
      enabled                     = bool
      log_analytics_workspace_id  = string
      manage_config               = bool
      containerlog_schema_version = string
    })
    prometheus = object({
      remote_write = any
    })
  })
  nullable = false
}

variable "labels" {
  description = "Labels to be applied to all Kubernetes resources."
  type        = map(string)
  nullable    = false
}

variable "tags" {
  description = "Tags to be applied to all resources."
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

variable "experimental" {
  description = "Provide experimental feature flag configuration."
  type = object({
    aad_pod_identity_finalizer_wait             = string
    fluent_bit_use_memory_buffer                = bool
    fluentd_memory_override                     = string
    prometheus_memory_override                  = string
    fluent_bit_aggregator_cpu_requests_override = string
    fluent_bit_aggregator_cpu_limits_override   = string
    fluent_bit_aggregator_memory_override       = string
    fluent_bit_collector_multiline_parsers = map(object({
      rules = list(object({
        name           = string
        pattern        = string
        next_rule_name = string
      }))
      workloads = list(object({
        namespace  = string
        pod_prefix = string
      }))
    }))
  })
}
