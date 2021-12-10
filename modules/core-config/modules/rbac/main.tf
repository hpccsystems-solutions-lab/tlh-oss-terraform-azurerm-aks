resource "kubectl_manifest" "clusterroles" {
  for_each = fileset(path.module, "clusterroles/*.yaml")

  yaml_body = file("${path.module}/${each.value}")
}

resource "kubectl_manifest" "cluster_admin_rolebinding" {
  yaml_body = templatefile("${path.module}/clusterrolebindings/lnrs-cluster-admin.yaml.tpl", local.cluster_roles)
}

resource "kubectl_manifest" "cluster_view_rolebinding" {
  yaml_body = templatefile("${path.module}/clusterrolebindings/lnrs-cluster-view.yaml.tpl", local.cluster_roles)
}

resource "kubectl_manifest" "standard_view_rolebinding" {
  yaml_body = templatefile("${path.module}/clusterrolebindings/lnrs-standard-view.yaml.tpl", local.cluster_roles)
}

resource "azurerm_role_assignment" "aks_cluster_user_role" {
  for_each = merge(values(var.azuread_clusterrole_map)...)

  scope                = var.cluster_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = each.value
}