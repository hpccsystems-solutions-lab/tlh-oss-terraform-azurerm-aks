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