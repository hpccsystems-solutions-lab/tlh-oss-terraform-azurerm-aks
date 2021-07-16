resource "azurerm_role_definition" "resource_group_reader" {
  name        = "${var.cluster_name}-external-dns-rg"
  scope       = local.dns_zone_resource_group_id
  description = "Custom role for external-dns to manage DNS records"

  assignable_scopes = [local.dns_zone_resource_group_id]

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
  name        = "${var.cluster_name}-external-dns-zone"
  scope       = element(local.dns_zone_ids, 0)
  description = "Custom role for external-dns to manage DNS records"

  assignable_scopes = local.dns_zone_ids

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
  identity_name       = "external-dns"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  tags                = var.tags
  namespace           = local.namespace

  roles = concat(
    [
      {
        role_definition_resource_id = azurerm_role_definition.resource_group_reader.role_definition_resource_id
        scope                       = local.dns_zone_resource_group_id
      }
    ],
    [for zone in toset(var.dns_zones.names) :
      {
        role_definition_resource_id = azurerm_role_definition.dns_zone_contributor.role_definition_resource_id
        scope                       = "${local.dns_zone_resource_group_id}/providers/Microsoft.Network/dnszones/${zone}"
      }
    ]
  )
}

resource "helm_release" "main" {
  depends_on = [module.identity]

  name       = "external-dns"
  namespace  = local.namespace

  repository = "https://charts.bitnami.com/bitnami/"
  chart      = "external-dns"
  version    = local.chart_version
  skip_crds  = true

  values = [
    yamlencode(local.chart_values)
  ]
}
