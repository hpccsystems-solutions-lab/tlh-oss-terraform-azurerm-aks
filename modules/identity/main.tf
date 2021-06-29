resource "azurerm_user_assigned_identity" "main" {
  name                = "${var.cluster_name}-${var.identity_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "main" {
  count = length(var.roles)

  scope              = var.roles[count.index].scope
  role_definition_id = var.roles[count.index].role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.main.principal_id
}

resource "kubectl_manifest" "identity" {
  yaml_body = yamlencode(local.identity)
}

resource "kubectl_manifest" "identity_binding" {
  depends_on = [kubectl_manifest.identity]

  yaml_body = yamlencode(local.identity_binding)
}