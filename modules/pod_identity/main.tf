resource "azurerm_role_assignment" "k8s_virtual_machine_contributor" {
  scope                = data.azurerm_resource_group.node_rg.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = var.aks_identity
}

resource "azurerm_role_assignment" "k8s_managed_identity_operator" {
  scope                = data.azurerm_resource_group.node_rg.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = var.aks_identity
}

resource "kubectl_manifest" "aad_pod_identity_crd_azure_assigned_identities" {
  yaml_body = templatefile("${path.module}/kubernetes_manifests/customresourcedefinition-aadpodidentity-azureassignedidentities.yaml.template",{})
}

resource "kubectl_manifest" "aad_pod_identity_crd_azure_identities" {
  yaml_body = templatefile("${path.module}/kubernetes_manifests/customresourcedefinition-aadpodidentity-azureidentities.yaml.template",{})
}

resource "kubectl_manifest" "aad_pod_identity_crd_azure_identity_bindings" {
  yaml_body = templatefile("${path.module}/kubernetes_manifests/customresourcedefinition-aadpodidentity-azureidentitybindings.yaml.template",{})
}

resource "kubectl_manifest" "aad_pod_identity_crd_azure_pod_identity_exceptions" {
  yaml_body = templatefile("${path.module}/kubernetes_manifests/customresourcedefinition-aadpodidentity-azurepodidentityexceptions.yaml.template",{})
}

resource "helm_release" "aad_pod_identity" {
  depends_on = [
    azurerm_role_assignment.k8s_virtual_machine_contributor,
    azurerm_role_assignment.k8s_managed_identity_operator,
    kubectl_manifest.aad_pod_identity_crd_azure_assigned_identities,
    kubectl_manifest.aad_pod_identity_crd_azure_identities,
    kubectl_manifest.aad_pod_identity_crd_azure_identity_bindings,
    kubectl_manifest.aad_pod_identity_crd_azure_pod_identity_exceptions,
  ]

  name       = "aad-pod-identity"
  namespace  = "kube-system"
  repository = "https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts"
  chart      = "aad-pod-identity"
  version    = "4.0.0"

  skip_crds = true

  values = [<<-EOT
    rbac:
      allowAccessToSecrets: false
    installCRDs: false
    nmi:
      allowNetworkPluginKubenet: ${(var.network_plugin == "kubenet" ? true : false)}
  EOT
  ]
}