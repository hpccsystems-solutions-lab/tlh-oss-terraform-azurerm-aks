module "identity" {
  source = "../../../identity"

  location            = var.location
  resource_group_name = var.resource_group_name

  workload_identity = var.workload_identity && local.use_aad_workload_identity
  oidc_issuer_url   = var.cluster_oidc_issuer_url

  name      = "${var.cluster_name}-fluentd"
  subjects  = ["system:serviceaccount:${var.namespace}:${local.service_account_name}"]
  namespace = var.namespace
  labels    = var.labels

  roles = [{
    id    = "Reader"
    scope = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.ContainerService/managedClusters/${var.cluster_name}"
  }]

  tags = var.tags
}
