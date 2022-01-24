resource "azurerm_user_assigned_identity" "main" {
  name                = "${var.cluster_name}-${var.identity_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "main" {
  count = length(var.roles)

  ## Support both (mutually exclusive) options depending on the input (if an Azure path use role_definition_id)
  role_definition_id   = length(regexall("^/subscription", var.roles[count.index].role_definition_resource_id)) > 0 ? var.roles[count.index].role_definition_resource_id : null
  role_definition_name = length(regexall("^/subscription", var.roles[count.index].role_definition_resource_id)) > 0 ? null : var.roles[count.index].role_definition_resource_id

  scope              = var.roles[count.index].scope
  principal_id       = azurerm_user_assigned_identity.main.principal_id
}

resource "kubectl_manifest" "identity" {
  yaml_body = yamlencode(local.identity)

  server_side_apply = true
}

resource "kubectl_manifest" "identity_binding" {
  yaml_body = yamlencode(local.identity_binding)

  server_side_apply = true
}
