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

module "pod_identity" {
  depends_on = [azurerm_role_assignment.main]

  source = "../../../pod-identity/identity"

  namespace = var.namespace
  identity_name = azurerm_user_assigned_identity.main.name
  identity_client_id = azurerm_user_assigned_identity.main.client_id
  identity_resource_id = azurerm_user_assigned_identity.main.id
}

resource "helm_release" "main" {
  depends_on = [module.pod_identity]

  name       = "external-dns"
  namespace  = var.namespace
  repository = "https://charts.bitnami.com/bitnami/"
  chart      = "external-dns"
  version    = var.helm_chart_version
  skip_crds  = true

  values = [<<-EOT
---
replicas: 2

nodeSelector:
  agentpool: ${var.node_pool_name}

podLabels:
  aadpodidbinding: ${azurerm_user_assigned_identity.main.name}

tolerations:
${yamlencode(var.tolerations)}

priorityClassName: lnrs-platform-critical

policy: sync

rbac:
  create: 'true'

sources:
  - service
  - ingress

provider: azure

domainFilters:${indent(2, "\n${yamlencode([for name in var.dns_zones.names : name])}")}

txtOwnerId: ${var.cluster_name}

azure:
  tenantId: ${var.azure_tenant_id}
  subscriptionId: ${var.azure_subscription_id}
  resourceGroup: ${var.dns_zones.resource_group_name}
  useManagedIdentityExtension: true
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
