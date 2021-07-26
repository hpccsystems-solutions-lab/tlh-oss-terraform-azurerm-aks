locals {
  dns_zone_resource_group_id = "/subscriptions/${var.azure_subscription_id}/resourceGroups/${var.dns_zones.resource_group_name}"
  dns_zone_ids               = [for zone in toset(var.dns_zones.names) : "${local.dns_zone_resource_group_id}/providers/Microsoft.Network/dnszones/${zone}"]

  namespace = "dns"

  chart_version = "5.2.0"

  chart_values = {

    rbac = {
      create = "true"
    }

    replicas = 1

    podLabels = {
      aadpodidbinding        = module.identity.name
      "lnrs.io/k8s-platform" = "true"
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

    sources = concat(["service", "ingress"], var.additional_sources)

    policy = "sync"

    logLevel = "debug"

    txtOwnerId : var.cluster_name

    provider = "azure"

    azure = {
      resourceGroup               = var.dns_zones.resource_group_name
      subscriptionId              = var.azure_subscription_id
      tenantId                    = var.azure_tenant_id
      useManagedIdentityExtension = true
      userAssignedIdentityID      = module.identity.client_id
    }

    domainFilters = [for name in var.dns_zones.names : name]
  }
}
