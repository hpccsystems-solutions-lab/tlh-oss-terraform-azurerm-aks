locals {
  azure_environments = {
    "public"       = "AzurePublicCloud"
    "usgovernment" = "AzureUSGovernmentCloud"
  }

  azure_environment = local.azure_environments[var.azure_env]

  az_count = length(var.availability_zones)

  system_namespaces = [
    "default",
    "kube-system"
  ]

  namespaces = concat([
    "cert-manager",
    "dns",
    "logging",
    "ingress-core-internal",
    "monitoring"
  ], var.core_services_config.fluent_bit_aggregator.enabled ? ["observability"] : [])

  namespace_pod_security_labels = {
    "pod-security.kubernetes.io/audit" = "baseline"
    "pod-security.kubernetes.io/warn"  = "baseline"
  }

  loki_output = {
    enabled       = var.core_services_config.loki.enabled
    host          = var.core_services_config.loki.enabled ? module.loki[0].host : ""
    port          = var.core_services_config.loki.enabled ? module.loki[0].port : -1
    node_logs     = var.core_services_config.loki.node_logs
    workload_logs = true
  }

  azure_storage_nodes_output = {
    enabled     = var.logging.nodes.storage_account.enabled
    id          = var.logging.nodes.storage_account.enabled ? coalesce(var.logging.nodes.storage_account.id, var.logging.storage_account_config.id) : null
    container   = var.logging.nodes.storage_account.container
    path_prefix = var.logging.nodes.storage_account.path_prefix
  }

  azure_storage_workloads_output = {
    enabled     = var.logging.workloads.storage_account.enabled
    id          = var.logging.workloads.storage_account.enabled ? coalesce(var.logging.workloads.storage_account.id, var.logging.storage_account_config.id) : null
    container   = var.logging.workloads.storage_account.container
    path_prefix = var.logging.workloads.storage_account.path_prefix
  }

  ingress_internal_core = merge(var.core_services_config.ingress_internal_core, var.core_services_config.ingress_internal_core.subdomain_suffix == null ? { subdomain_suffix = var.cluster_name } : {}, {
    annotations = {
      "lnrs.io/zone-type" = var.core_services_config.ingress_internal_core.public_dns ? "public" : "private"
    }
  })

  resource_overrides = merge(flatten([
    for service, settings in var.core_services_config : [
      for container, resources in lookup(settings, "resource_overrides", {}) : {
        "${service}_${container}" = {
          cpu       = resources.cpu
          cpu_limit = resources.cpu_limit != null ? resources.cpu_limit : (resources.cpu != null ? ceil(resources.cpu / 1000) * 1000 : null)
          memory    = resources.memory
        }
      }
    ]
  ])...)

}
