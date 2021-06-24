resource "kubectl_manifest" "crds" {
  for_each = local.crd_files

  yaml_body = file(each.value)
}

resource "kubectl_manifest" "resources" {
  for_each = local.resource_files

  yaml_body = file(each.value)

  depends_on = [
    kubectl_manifest.crds
  ]
}

resource "azurerm_role_definition" "resource_group_reader" {
  for_each    = var.dns_zones

  name        = "${var.cluster_name}-cert-manager-rg-${replace(each.key, ".", "-")}"
  scope       = "/subscriptions/${var.azure_subscription_id}/resourceGroups/${each.value}"
  description = "Custom role for cert-manager to manage DNS records"

  assignable_scopes = ["/subscriptions/${var.azure_subscription_id}/resourceGroups/${each.value}"]

  permissions {
    actions = [
      "Microsoft.Resources/subscriptions/resourceGroups/read",
    ]
    data_actions     = []
    not_actions      = []
    not_data_actions = []
  }
}

resource "azurerm_role_definition" "dns_zone_contributor" {
  for_each    = var.dns_zones

  name        = "${var.cluster_name}-cert-manager-dns-${replace(each.key, ".", "-")}"
  scope       = "/subscriptions/${var.azure_subscription_id}/resourceGroups/${each.value}/providers/Microsoft.Network/dnszones/${each.key}"
  description = "Custom role for cert-manager to manage DNS records"

  assignable_scopes = ["/subscriptions/${var.azure_subscription_id}/resourceGroups/${each.value}/providers/Microsoft.Network/dnszones/${each.key}"]

  permissions {
    actions = [
      "Microsoft.Network/dnsZones/*"
    ]
    data_actions     = []
    not_actions      = []
    not_data_actions = []
  }
}

module "identity" {
  source = "../../../identity"

  cluster_name        = var.cluster_name
  identity_name       = "cert-manager"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  tags                = var.tags

  namespace = var.namespace
  roles = concat(
    [for zone,rg in var.dns_zones:
      { 
        role_definition_resource_id = azurerm_role_definition.resource_group_reader[zone].role_definition_resource_id
        scope                       = "/subscriptions/${var.azure_subscription_id}/resourceGroups/${rg}"
      }
    ],
    [for zone,rg in var.dns_zones:
      {
        role_definition_resource_id = azurerm_role_definition.dns_zone_contributor[zone].role_definition_resource_id
        scope                       = "/subscriptions/${var.azure_subscription_id}/resourceGroups/${rg}/providers/Microsoft.Network/dnszones/${zone}"
      }
    ]
  )
}

resource "helm_release" "main" {
  depends_on = [module.identity]

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.4.0"
  namespace  = var.namespace
  skip_crds  = true

  max_history = 20
  timeout     = 300

  values = [
    yamlencode(local.chart_values)
  ]
}

resource "kubectl_manifest" "issuers" {
  for_each = local.issuers

  depends_on = [helm_release.main]

  yaml_body = yamlencode(each.value)
}