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

resource "kubectl_manifest" "crds" {
  for_each = fileset(path.module, "crds/*.yaml")

  yaml_body = file("${path.module}/${each.value}")
}

resource "helm_release" "aad_pod_identity" {
  depends_on = [
    azurerm_role_assignment.k8s_virtual_machine_contributor,
    azurerm_role_assignment.k8s_managed_identity_operator_parent,
    azurerm_role_assignment.k8s_managed_identity_operator_node,
    kubectl_manifest.crds
  ]

  name       = "aad-pod-identity"
  namespace  = "kube-system"
  repository = "https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts"
  chart      = "aad-pod-identity"
  version    = local.helm_chart_version

  skip_crds = true

  values = [<<-EOT
---
rbac:
  allowAccessToSecrets: false
installCRDs: false
forceNamespaced: "false"
mic:
  nodeSelector:
    kubernetes.azure.com/mode: system
  tolerations:
    - key: "CriticalAddonsOnly"
      operator: "Exists"
      effect: "NoSchedule"
nmi:
  allowNetworkPluginKubenet: ${(var.network_plugin == "kubenet" ? true : false)}
  tolerations:
    - operator: "Exists"
EOT
  ]
}