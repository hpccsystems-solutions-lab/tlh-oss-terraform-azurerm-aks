resource "azurerm_role_definition" "main" {
  name        = "${var.cluster_name}-external-dns"
  scope       = data.azurerm_resource_group.dns_zone.id
  description = "Custom role for external-dns to manage DNS records"

  assignable_scopes = [data.azurerm_resource_group.dns_zone.id]

  permissions {
    actions = var.dns_permissions
  }
}

module "identity" {
  source = "../../../identity"

  cluster_name        = var.cluster_name
  identity_name       = "external-dns"
  resource_group_name = data.azurerm_resource_group.cluster.name
  location            = data.azurerm_resource_group.cluster.location
  tags                = var.tags

  namespace = var.namespace
  role_definition_resource_id = azurerm_role_definition.main.role_definition_resource_id
  scope                       = data.azurerm_resource_group.dns_zone.id
}

resource "helm_release" "main" {
  depends_on = [module.identity]

  name       = "external-dns"
  namespace  = var.namespace
  repository = "https://charts.bitnami.com/bitnami/"
  chart      = "external-dns"
  version    = var.helm_chart_version
  skip_crds  = true

  values = [<<-EOT
---

logLevel: debug
namespace: ${var.namespace}

replicas: 1

nodeSelector:
  kubernetes.azure.com/mode: system

podLabels:
  aadpodidbinding: ${module.identity.name}

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
  userAssignedIdentityID: ${module.identity.client_id}

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