locals {
  azure_environments = {
    "public"       = "AzurePublicCloud"
    "usgovernment" = "AzureUSGovernmentCloud"
  }

  azure_environment = local.azure_environments[var.azure_env]

  az_count = length(var.availability_zones)

  namespaces = [
    "cert-manager",
    "dns",
    "logging",
    "ingress-core-internal",
    "monitoring"
  ]

  ingress_internal_core = merge(var.core_services_config.ingress_internal_core, var.core_services_config.ingress_internal_core.subdomain_suffix == null ? { subdomain_suffix = var.cluster_name } : {}, {
    annotations = {
      "lnrs.io/zone-type" = var.core_services_config.ingress_internal_core.public_dns ? "public" : "private"
    }
  })
}
