resource "kubernetes_namespace" "main" {
  metadata {
    name   = var.namespace_name
    labels = {
      "app.kubernetes.io/name"       = var.namespace_name
      "app.kubernetes.io/part-of"    = var.namespace_name
      "app.kubernetes.io/managed-by" = "terraform"
      "lnrs.io/run-level"           = "0"
      "lnrs.io/run-class"           = "default"
      "lnrs.io/cloud-provider"      = "all"
    }
  }
}

resource "azurerm_role_definition" "main" {
  name        = "${var.cluster_name}-external-dns"
  scope       = data.azurerm_resource_group.dns_zone.id
  description = "Custom role for external-dns to manage DNS records"

  assignable_scopes = [data.azurerm_resource_group.dns_zone.id]

  permissions {
    actions = var.dns_permissions
  }
}

resource "azurerm_user_assigned_identity" "main" {
  name = "${var.cluster_name}-external-dns"

  resource_group_name = data.azurerm_resource_group.cluster.name
  location            = data.azurerm_resource_group.cluster.location

  tags = var.tags
}

resource "azurerm_role_assignment" "main" {
  scope              = data.azurerm_resource_group.dns_zone.id
  role_definition_id = azurerm_role_definition.main.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.main.principal_id
}

resource "helm_release" "main" {
  name       = "external-dns"
  namespace  = kubernetes_namespace.main.metadata.0.name
  repository = "https://charts.bitnami.com/bitnami/"
  chart      = "external-dns"
  version    = var.helm_chart_version
  skip_crds  = true

  values = [<<-EOT
---
replicas: 2

nodeSelector:
  agentpool: ${var.node_pool_name}

priorityClassName: lnrs-platform-critical

policy: sync

rbac:
  create: 'true'

sources:
  - service
  - ingress

provider: azure

domainFilters:
  - ${var.dns_zone_name}

txtOwnerId: ${var.cluster_name}

azure:
  tenantId: ${var.azure_tenant_id}
  subscriptionId: ${var.azure_subscription_id}
  useManagedIdentityExtension: 'true'
  resourceGroup: ${data.azurerm_resource_group.dns_zone.name}
  userAssignedIdentityID: ${azurerm_user_assigned_identity.main.client_id}

resources:
  requests:
    cpu: ${var.resources_request_cpu}
    memory: ${var.resources_request_memory}
  limits:
    cpu: ${var.resources_limit_cpu}
    memory: ${var.resources_limit_memory}

logLevel: debug
EOT
  ]
}