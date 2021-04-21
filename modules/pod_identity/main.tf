resource "azurerm_role_assignment" "k8s_virtual_machine_contributor" {
  scope                = data.azurerm_resource_group.node.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = var.aks_identity
}

resource "azurerm_role_assignment" "k8s_managed_identity_operator_parent" {
  scope                = data.azurerm_resource_group.parent.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = var.aks_identity
}

resource "azurerm_role_assignment" "k8s_managed_identity_operator_node" {
  scope                = data.azurerm_resource_group.node.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = var.aks_identity
}

resource "helm_release" "aad_pod_identity" {
  depends_on = [azurerm_role_assignment.k8s_virtual_machine_contributor,
                azurerm_role_assignment.k8s_managed_identity_operator_parent,
                azurerm_role_assignment.k8s_managed_identity_operator_node]
  name       = "aad-pod-identity"
  namespace  = "kube-system"
  repository = "https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts"
  chart      = "aad-pod-identity"
  version    = "4.0.0"

  values = [<<-EOT
    rbac:
      allowAccessToSecrets: false
    installCRDs: true
    nmi:
      allowNetworkPluginKubenet: ${(var.network_plugin == "kubenet" ? true : false)}
  EOT
  ]
}