module "identity" {
  source = "../../../identity"

  location            = var.location
  resource_group_name = var.resource_group_name

  workload_identity = local.use_aad_workload_identity
  oidc_issuer_url   = var.cluster_oidc_issuer_url

  name      = "${var.cluster_name}-${local.name}"
  subjects  = ["system:serviceaccount:${var.namespace}:${local.service_account_name}"]
  namespace = var.namespace
  labels    = var.labels

  roles = [{
    id    = "Storage Blob Data Contributor"
    scope = azurerm_storage_account.data.id
  }]

  tags = var.tags
}
