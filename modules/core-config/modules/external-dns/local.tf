locals {
  chart_values = {
    azure = {
      resourceGroup = var.dns_zones.resource_group_name
      subscriptionId = var.azure_subscription_id
      tenantId = var.azure_tenant_id
      useManagedIdentityExtension = true
      userAssignedIdentityID = module.identity.client_id
    }
    domainFilters = [for name in var.dns_zones.names : name]
    logLevel = "debug"
    namespace = var.namespace
    nodeSelector = {
      "kubernetes.azure.com/mode" = "system"
    }
    podLabels = {
      aadpodidbinding = "module.identity.name"
    }
    policy = "sync"
    priorityClassName = "lnrs-platform-critical"
    provider = "azure"
    rbac = {
      create = "true"
    }
    replicas = 1
    resources = {
      limits = {
        cpu = var.resources_limit_cpu
        memory = var.resources_limit_memory
      }
      requests = {
        cpu = var.resources_request_cpu
        memory = var.resources_request_memory
      }
    }
    sources = [
      "service",
      "ingress"
    ]
    tolerations = var.tolerations
    txtOwnerId = var.cluster_name
  }
}