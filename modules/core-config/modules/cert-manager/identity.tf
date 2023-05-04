module "identity" {
  source = "../../../identity"

  location            = var.location
  resource_group_name = var.resource_group_name

  workload_identity = local.use_aad_workload_identity
  oidc_issuer_url   = var.cluster_oidc_issuer_url

  name      = "${var.cluster_name}-cert-manager"
  subjects  = ["system:serviceaccount:${var.namespace}:${local.service_account_name}"]
  namespace = var.namespace
  labels    = var.labels

  roles = concat([for zone in var.acme_dns_zones : {
    id    = "DNS Zone Contributor"
    scope = "/subscriptions/${var.subscription_id}/resourceGroups/${var.dns_resource_group_lookup[zone]}/providers/Microsoft.Network/dnszones/${zone}"
  }])

  tags = var.tags
}
