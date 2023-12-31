locals {
  chart_version = "1.13.1"

  use_aad_workload_identity = true

  chart_values = {
    serviceMonitor = {
      enabled = true
      additionalLabels = {
        "lnrs.io/monitoring-platform" = "true"
      }
    }

    priorityClassName = ""

    commonLabels = var.labels

    nodeSelector = {
      "kubernetes.io/os" = "linux"
      "lnrs.io/tier"     = "system"
    }

    tolerations = [
      {
        key      = "CriticalAddonsOnly"
        operator = "Exists"
      },
      {
        key      = "system"
        operator = "Exists"
      }
    ]

    resources = {
      requests = {
        cpu    = "10m"
        memory = "128Mi"
      }

      limits = {
        cpu    = "1000m"
        memory = "128Mi"
      }
    }

    logLevel  = local.log_level_lookup[var.log_level]
    logFormat = "json"

    sources = concat(["service", "ingress"], var.additional_sources)

    policy = "sync"

    txtOwnerId = var.cluster_name

    env = [{
      name  = "AZURE_ENVIRONMENT"
      value = var.azure_environment
    }]

    extraVolumeMounts = [{
      name      = "azure-config-file"
      mountPath = "/etc/kubernetes"
      readOnly  = true
    }]
  }

  chart_values_private = merge(local.chart_values, {
    nameOverride = "external-dns-private"

    serviceAccount = {
      create = true
      name   = local.private_service_account_name

      labels = local.use_aad_workload_identity ? {
        "azure.workload.identity/use" = "true"
      } : {}

      annotations = local.use_aad_workload_identity ? {
        "azure.workload.identity/client-id" = local.enable_private ? module.identity_private[0].client_id : ""
      } : {}
    }

    podLabels = merge(var.labels, local.use_aad_workload_identity ? { "azure.workload.identity/use" = "true" } : {
      aadpodidbinding = local.enable_private ? module.identity_private[0].name : ""
    })

    extraVolumes = [{
      name = "azure-config-file"
      secret = {
        secretName = local.enable_private ? kubernetes_secret.private_config[0].metadata[0].name : ""
        items = [{
          key  = "config"
          path = "azure.json"
        }]
      }
    }]

    provider = "azure-private-dns"

    domainFilters = var.private_domain_filters

    extraArgs = concat([
      "--azure-config-file=/etc/kubernetes/azure.json",
      "--annotation-filter=lnrs.io/zone-type in (private, public-private)"
    ], contains(var.additional_sources, "crd") ? local.crd_args : [])
  })

  chart_values_public = merge(local.chart_values, {
    nameOverride = "external-dns-public"

    serviceAccount = {
      create = true
      name   = local.public_service_account_name

      labels = local.use_aad_workload_identity ? {
        "azure.workload.identity/use" = "true"
      } : {}

      annotations = local.use_aad_workload_identity ? {
        "azure.workload.identity/client-id" = local.enable_public ? module.identity_public[0].client_id : ""
      } : {}
    }

    podLabels = merge(var.labels, local.use_aad_workload_identity ? { "azure.workload.identity/use" = "true" } : {
      aadpodidbinding = local.enable_public ? module.identity_public[0].name : ""
    })

    extraVolumes = [{
      name = "azure-config-file"
      secret = {
        secretName = local.enable_public ? kubernetes_secret.public_config[0].metadata[0].name : ""
        items = [{
          key  = "config"
          path = "azure.json"
        }]
      }
    }]

    provider = "azure"

    domainFilters = var.public_domain_filters

    extraArgs = concat([
      "--azure-config-file=/etc/kubernetes/azure.json",
      "--annotation-filter=lnrs.io/zone-type in (public, public-private)"
    ], contains(var.additional_sources, "crd") ? local.crd_args : [])
  })

  private_service_account_name = "external-dns-private"
  public_service_account_name  = "external-dns-public"

  crd_args = [
    "--crd-source-apiversion=externaldns.k8s.io/v1alpha1",
    "--crd-source-kind=DNSEndpoint"
  ]

  private_dns_zone_resource_group_name = one(distinct([for zone in var.private_domain_filters : var.dns_resource_group_lookup[zone]]))
  public_dns_zone_resource_group_name  = one(distinct([for zone in var.public_domain_filters : var.dns_resource_group_lookup[zone]]))

  enable_private = length(var.private_domain_filters) > 0 && local.private_dns_zone_resource_group_name != null
  enable_public  = length(var.public_domain_filters) > 0 && local.public_dns_zone_resource_group_name != null

  log_level_lookup = {
    "ERROR" = "error"
    "WARN"  = "warning"
    "INFO"  = "info"
    "DEBUG" = "debug"
  }

  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
}
