resource "kubectl_manifest" "resources" {
  for_each = local.resource_files

  yaml_body = file(each.value)

  server_side_apply = true
}

resource "kubectl_manifest" "resource_objects" {
  for_each = local.resource_objects

  yaml_body = yamlencode(each.value)

  server_side_apply = true
}

module "identity_private" {
  count = length(var.private_domain_filters.names) > 0 ? 1 : 0

  source = "../../../identity"

  cluster_name        = var.cluster_name
  identity_name       = "external-dns-private"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  tags                = var.tags
  namespace           = local.namespace

  roles = concat(
    [
      {
        role_definition_resource_id = "Reader"
        scope                       = local.private_dns_zone_resource_group_id
      }
    ],
    [for zone in toset(var.private_domain_filters.names) :
      {
        role_definition_resource_id = "Private DNS Zone Contributor"
        scope                       = "${local.private_dns_zone_resource_group_id}/providers/Microsoft.Network/privateDnsZones/${zone}"
      }
    ]
  )
}

module "identity_public" {
  count = length(var.public_domain_filters.names) > 0 ? 1 : 0

  source = "../../../identity"

  cluster_name        = var.cluster_name
  identity_name       = "external-dns-public"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  tags                = var.tags
  namespace           = local.namespace

  roles = concat(
    [
      {
        role_definition_resource_id = "Reader"
        scope                       = local.public_dns_zone_resource_group_id
      }
    ],
    [for zone in toset(var.public_domain_filters.names) :
      {
        role_definition_resource_id = "DNS Zone Contributor"
        scope                       = "${local.public_dns_zone_resource_group_id}/providers/Microsoft.Network/dnszones/${zone}"
      }
    ]
  )
}

resource "kubernetes_secret" "azure_private_config_file" {
  count = length(var.private_domain_filters.names) > 0 ? 1 : 0

  metadata {
    name      = local.azure-private-secret-name
    namespace = local.namespace
  }

  type = "Opaque"

  data = {
    "azure-private.json" = <<CONFIG
       {
         "cloud": "${var.azure_environment}",
         "tenantId": "${var.azure_tenant_id}",
         "subscriptionId": "${var.azure_subscription_id}",
         "resourceGroup": "${var.private_domain_filters.resource_group_name}",
         "useManagedIdentityExtension": true
       }
       CONFIG
  }

  depends_on = [module.identity_private]
}

resource "kubernetes_secret" "azure_public_config_file" {
  count = length(var.public_domain_filters.names) > 0 ? 1 : 0

  metadata {
    name      = local.azure-public-secret-name
    namespace = local.namespace
  }

  type = "Opaque"

  data = {
    "azure-public.json" = <<CONFIG
       {
         "cloud": "${var.azure_environment}",
         "tenantId": "${var.azure_tenant_id}",
         "subscriptionId": "${var.azure_subscription_id}",
         "resourceGroup": "${var.public_domain_filters.resource_group_name}",
         "useManagedIdentityExtension": true
       }
       CONFIG
  }
  
  depends_on = [module.identity_public]
}

resource "helm_release" "private" {
  count = length(var.private_domain_filters.names) > 0 ? 1 : 0

  name      = "external-dns-private"
  namespace = local.namespace

  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = local.chart_version
  skip_crds  = true

  values = [
    yamlencode(local.chart_values_private)
  ]

  depends_on = [
    module.identity_private,
    kubernetes_secret.azure_private_config_file
  ]
}

resource "helm_release" "public" {
  count = length(var.public_domain_filters.names) > 0 ? 1 : 0

  name      = "external-dns-public"
  namespace = local.namespace

  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = local.chart_version
  skip_crds  = true

  values = [
    yamlencode(local.chart_values_public)
  ]

  depends_on = [
    module.identity_public,
    kubernetes_secret.azure_public_config_file
  ]
}
