module "identity_grafana" {
  source = "../../../identity"

  location            = var.location
  resource_group_name = var.resource_group_name

  workload_identity = var.workload_identity && local.use_aad_workload_identity
  oidc_issuer_url   = var.cluster_oidc_issuer_url

  name      = "${var.cluster_name}-grafana"
  subjects  = ["system:serviceaccount:${var.namespace}:${local.grafana_service_account_name}"]
  namespace = var.namespace
  labels    = var.labels

  roles = concat(
    [{ id = "Reader", scope = "/subscriptions/${var.subscription_id}" }],
    [for x in var.grafana_log_analytics_workspace_ids : { id = "Monitoring Reader", scope = x }]
  )

  tags = var.tags
}

module "identity_thanos" {
  source = "../../../identity"

  location            = var.location
  resource_group_name = var.resource_group_name

  workload_identity = var.workload_identity && local.use_aad_workload_identity
  oidc_issuer_url   = var.cluster_oidc_issuer_url

  name = "${var.cluster_name}-thanos"

  subjects = [
    "system:serviceaccount:${var.namespace}:${local.prometheus_service_account_name}",
    "system:serviceaccount:${var.namespace}:${local.thanos_compact_service_account_name}",
    "system:serviceaccount:${var.namespace}:${local.thanos_rule_service_account_name}",
    "system:serviceaccount:${var.namespace}:${local.thanos_store_gateway_service_account_name}"
  ]

  namespace = var.namespace
  labels    = var.labels

  roles = [{
    id    = "Storage Blob Data Contributor"
    scope = azurerm_storage_account.data.id
  }]

  tags = var.tags
}
