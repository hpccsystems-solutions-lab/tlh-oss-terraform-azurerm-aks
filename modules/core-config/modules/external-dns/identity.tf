module "identity_private" {
  source = "../../../identity"
  count  = local.enable_private ? 1 : 0

  location            = var.location
  resource_group_name = var.resource_group_name

  workload_identity = local.use_aad_workload_identity
  oidc_issuer_url   = var.cluster_oidc_issuer_url

  name      = "${var.cluster_name}-external-dns-private"
  subjects  = ["system:serviceaccount:${var.namespace}:${local.private_service_account_name}"]
  namespace = var.namespace
  labels    = var.labels

  roles = concat([{
    id    = "Reader"
    scope = "/subscriptions/${var.subscription_id}/resourceGroups/${local.private_dns_zone_resource_group_name}"
    }], [for zone in var.private_domain_filters : {
    id    = "Private DNS Zone Contributor"
    scope = "/subscriptions/${var.subscription_id}/resourceGroups/${local.private_dns_zone_resource_group_name}/providers/Microsoft.Network/privateDnsZones/${zone}"
  }])

  tags = var.tags
}

module "identity_public" {
  source = "../../../identity"
  count  = local.enable_public ? 1 : 0

  location            = var.location
  resource_group_name = var.resource_group_name

  workload_identity = local.use_aad_workload_identity
  oidc_issuer_url   = var.cluster_oidc_issuer_url

  name      = "${var.cluster_name}-external-dns-public"
  subjects  = ["system:serviceaccount:${var.namespace}:${local.public_service_account_name}"]
  namespace = var.namespace
  labels    = var.labels

  roles = concat([{
    id    = "Reader"
    scope = "/subscriptions/${var.subscription_id}/resourceGroups/${local.public_dns_zone_resource_group_name}"
    }], [for zone in var.public_domain_filters : {
    id    = "DNS Zone Contributor"
    scope = "/subscriptions/${var.subscription_id}/resourceGroups/${local.public_dns_zone_resource_group_name}/providers/Microsoft.Network/dnszones/${zone}"
  }])

  tags = var.tags
}
