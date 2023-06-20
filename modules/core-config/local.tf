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

  ingress_internal_core = merge(var.core_services_config.ingress_internal_core, var.core_services_config.ingress_internal_core.subdomain_suffix == null ? { subdomain_suffix = var.cluster_name } : {}, {
    annotations = {
      "lnrs.io/zone-type" = var.core_services_config.ingress_internal_core.public_dns ? "public" : "private"
    }
  })
}
