locals {
  private_dns_zone_resource_group_id = "/subscriptions/${var.azure_subscription_id}/resourceGroups/${var.private_domain_filters.resource_group_name}"
  public_dns_zone_resource_group_id  = "/subscriptions/${var.azure_subscription_id}/resourceGroups/${var.public_domain_filters.resource_group_name}"
  private_dns_zone_ids               = [for zone in toset(var.private_domain_filters.names) : "${local.private_dns_zone_resource_group_id}/providers/Microsoft.Network/privateDnsZones/${zone}"]
  public_dns_zone_ids                = [for zone in toset(var.public_domain_filters.names) : "${local.public_dns_zone_resource_group_id}/providers/Microsoft.Network/dnszones/${zone}"] 

  namespace = "dns"

  azure-private-secret-name = "azure-private-config-file"
  azure-public-secret-name = "azure-public-config-file"

  azure-private-json = "azure-private.json"
  azure-public-json = "azure-public.json"
  
  chart_version = "1.2.0"

  chart_values = {

    serviceMonitor = {
      enabled = true
      additionalLabels = {
        "lnrs.io/monitoring-platform" = "core-prometheus"
      }
    }

    priorityClassName = "system-cluster-critical"

    nodeSelector = {
      "kubernetes.io/os"          = "linux"
      "kubernetes.azure.com/mode" = "system"
    }

    tolerations = [{
      key      = "CriticalAddonsOnly"
      operator = "Exists"
      effect   = "NoSchedule"
    }]

    resources = {
      requests = {
        cpu    = "10m"
        memory = "64Mi"
      }

      limits = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }

    logFormat = "json"

    logLevel = "debug"

    sources = concat(["service", "ingress"], var.additional_sources)

    policy = "sync"

    txtOwnerId = var.cluster_name

    env = [{
      name  = "AZURE_ENVIRONMENT"
      value = var.azure_environment
    }]

  }

  chart_values_private = merge(local.chart_values, {
    nameOverride = "external-dns-private"

    podLabels = {
      aadpodidbinding        = "${var.cluster_name}-external-dns-private"
      "lnrs.io/k8s-platform" = "true"
    }

    extraVolumeMounts = [{
      name = local.azure-private-secret-name
      mountPath = "/etc/kubernetes"
      readOnly = true
    }]

    extraVolumes = [{
      name = local.azure-private-secret-name
      secret = {
        secretName = local.azure-private-secret-name
        items = [{
          key  = local.azure-private-json
          path = local.azure-private-json
        }]
      }
    }]

    provider = "azure-private-dns"

    domainFilters = var.private_domain_filters.names

    extraArgs = [
      "--azure-config-file=/etc/kubernetes/${local.azure-private-json}"
    ]
  })

  chart_values_public = merge(local.chart_values, {
    nameOverride = "external-dns-public"

    podLabels = {
      aadpodidbinding        = "${var.cluster_name}-external-dns-public"
      "lnrs.io/k8s-platform" = "true"
    }

    extraVolumeMounts = [{
      name = local.azure-public-secret-name
      mountPath = "/etc/kubernetes"
      readOnly = true
    }]

    extraVolumes = [{
      name = local.azure-public-secret-name
      secret = {
        secretName = local.azure-public-secret-name
        items = [{
          key  = local.azure-public-json
          path = local.azure-public-json
        }]
      }
    }]

    provider = "azure"

    domainFilters = var.public_domain_filters.names

    extraArgs = [
      "--azure-config-file=/etc/kubernetes/${local.azure-public-json}"
    ]
  })

  resource_files   = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
  resource_objects = {}
}
