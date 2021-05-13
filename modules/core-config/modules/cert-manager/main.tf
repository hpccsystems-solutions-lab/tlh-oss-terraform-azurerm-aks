resource "kubectl_manifest" "crds" {
  for_each = fileset(path.module, "crds/customresourcedefinition*.yaml")

  yaml_body = file("${path.module}/${each.value}")
}

resource "azurerm_role_definition" "resource_group_reader" {
  name        = "${var.cluster_name}-cert-manager-rg"
  scope       = data.azurerm_resource_group.dns_zone.id
  description = "Custom role for cert-manager to manage DNS records"

  assignable_scopes = [data.azurerm_resource_group.dns_zone.id]

  permissions {
    actions = [
      "Microsoft.Resources/subscriptions/resourceGroups/read",
    ]
  }
}

resource "azurerm_role_definition" "dns_zone_contributor" {
  name        = "${var.cluster_name}-cert-manager-dns"
  scope       = element([for zone in data.azurerm_dns_zone.dns_zone : zone.id], 0)
  description = "Custom role for cert-manager to manage DNS records"

  assignable_scopes = [for zone in data.azurerm_dns_zone.dns_zone : zone.id]

  permissions {
    actions = [
      "Microsoft.Network/dnsZones/*"
    ]
  }
}

module "identity" {
  source = "../../../identity"

  cluster_name        = var.cluster_name
  identity_name       = "cert-manager"
  resource_group_name = data.azurerm_resource_group.cluster.name
  location            = data.azurerm_resource_group.cluster.location
  tags                = var.tags

  namespace = var.namespace
  roles = concat([
    {
      role_definition_resource_id = azurerm_role_definition.resource_group_reader.role_definition_resource_id
      scope                       = data.azurerm_resource_group.dns_zone.id
    }],
    [ for zone in data.azurerm_dns_zone.dns_zone :
      {
        role_definition_resource_id = azurerm_role_definition.dns_zone_contributor.role_definition_resource_id
        scope                       = zone.id
      }
    ]
  )
}

resource "helm_release" "main" {
  depends_on = [module.identity]

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.3.1"
  namespace  = var.namespace
  skip_crds  = true

  max_history = 20
  timeout     = 300

  values = [
    yamlencode(local.chart_values)
  ]
}

module "issuer" {
  depends_on = [
    helm_release.main,
    kubectl_manifest.crds
  ]

  for_each = toset(var.dns_zones.names)

  source = "./issuer"

  name      = each.value
  namespace = var.namespace
  azure_environment = var.azure_environment
  azure_subscription_id = var.azure_subscription_id
  dns_zone = {
    name = each.value
    resource_group_name = var.dns_zones.resource_group_name
  }
  letsencrypt_endpoint = local.letsencrypt_endpoint[lower(var.letsencrypt_environment)]
  letsencrypt_email = var.letsencrypt_email
}