resource "kubectl_manifest" "clusterroles" {
  for_each = fileset(path.module, "clusterroles/*.yaml")

  yaml_body = file("${path.module}/${each.value}")
}

resource "kubectl_manifest" "cluster_admin_rolebinding" {
  yaml_body = templatefile("${path.module}/clusterrolebindings/lnrs-cluster-admin.yaml", var.azuread_k8s_role_map)
}

resource "kubectl_manifest" "cluster_view_rolebinding" {
  yaml_body = templatefile("${path.module}/clusterrolebindings/lnrs-cluster-view.yaml", var.azuread_k8s_role_map)
}

resource "kubectl_manifest" "standard_view_rolebinding" {
  yaml_body = templatefile("${path.module}/clusterrolebindings/lnrs-standard-view.yaml", var.azuread_k8s_role_map)
}

resource "azurerm_role_assignment" "aks_cluster_user_role" {
  for_each = merge(values(var.azuread_k8s_role_map)...)

  scope                = var.cluster_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = each.value
}
