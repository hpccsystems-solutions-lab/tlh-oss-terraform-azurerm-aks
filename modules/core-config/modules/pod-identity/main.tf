resource "azurerm_role_assignment" "k8s_virtual_machine_contributor" {
  scope                = local.node_resource_group_id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = var.aks_identity
}

resource "azurerm_role_assignment" "k8s_managed_identity_operator_parent" {
  scope                = local.parent_resource_group_id
  role_definition_name = "Managed Identity Operator"
  principal_id         = var.aks_identity
}

resource "azurerm_role_assignment" "k8s_managed_identity_operator_node" {
  scope                = local.node_resource_group_id
  role_definition_name = "Managed Identity Operator"
  principal_id         = var.aks_identity
}

resource "kubectl_manifest" "crds" {
  for_each = fileset(path.module, "crds/*.yaml")

  yaml_body = file("${path.module}/${each.value}")

  server_side_apply = true
}

resource "helm_release" "aad_pod_identity" {
  depends_on = [
    azurerm_role_assignment.k8s_virtual_machine_contributor,
    azurerm_role_assignment.k8s_managed_identity_operator_parent,
    azurerm_role_assignment.k8s_managed_identity_operator_node,
    kubectl_manifest.crds
  ]

  name      = "aad-pod-identity"
  namespace = "kube-system"

  repository = "https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts"
  chart      = "aad-pod-identity"
  version    = local.chart_version

  skip_crds = true

  values = [
    yamlencode(local.chart_values)
  ]
}
