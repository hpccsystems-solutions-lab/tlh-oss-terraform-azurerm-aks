resource "azurerm_role_assignment" "k8s_managed_identity_operator_cluster" {
  principal_id = var.kubelet_identity_id

  role_definition_name = "Managed Identity Operator"
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
}

resource "azurerm_role_assignment" "k8s_managed_identity_operator_node" {
  principal_id = var.kubelet_identity_id

  role_definition_name = "Managed Identity Operator"
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.node_resource_group_name}"
}

resource "azurerm_role_assignment" "k8s_virtual_machine_contributor_node" {
  principal_id = var.kubelet_identity_id

  role_definition_name = "Virtual Machine Contributor"
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.node_resource_group_name}"
}

resource "helm_release" "aad_pod_identity" {
  name      = "aad-pod-identity"
  namespace = var.namespace

  repository = "https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts"
  chart      = "aad-pod-identity"
  version    = local.chart_version
  skip_crds  = true

  max_history = 10
  timeout     = var.timeouts.helm_modify

  values = [
    yamlencode(local.chart_values)
  ]

  depends_on = [
    azurerm_role_assignment.k8s_managed_identity_operator_cluster,
    azurerm_role_assignment.k8s_managed_identity_operator_node,
    azurerm_role_assignment.k8s_virtual_machine_contributor_node
  ]
}

resource "time_sleep" "finalizer_wait" {
  destroy_duration = coalesce(var.experimental_finalizer_wait, "120s")

  depends_on = [
    helm_release.aad_pod_identity
  ]
}
