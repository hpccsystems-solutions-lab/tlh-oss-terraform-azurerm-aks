resource "azurerm_user_assigned_identity" "default" {
  name = var.name

  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_role_assignment" "default" {
  count = length(var.roles)

  principal_id = azurerm_user_assigned_identity.default.principal_id

  ## Support both (mutually exclusive) options depending on the input (if an Azure path use role_definition_id)
  role_definition_id   = length(regexall("^/subscription", var.roles[count.index].id)) > 0 ? var.roles[count.index].id : null
  role_definition_name = length(regexall("^/subscription", var.roles[count.index].id)) > 0 ? null : var.roles[count.index].id
  scope                = var.roles[count.index].scope
}

resource "azurerm_federated_identity_credential" "default" {
  for_each = var.workload_identity ? toset(local.subjects) : []

  name = var.name

  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.default.id

  issuer   = var.oidc_issuer_url
  audience = ["api://AzureADTokenExchange"]
  subject  = each.value
}

resource "kubectl_manifest" "azure_identity" {
  count = var.workload_identity ? 0 : 1

  yaml_body = yamlencode(local.azure_identity)

  server_side_apply = true
  wait              = true

  depends_on = [
    azurerm_user_assigned_identity.default
  ]
}

resource "kubectl_manifest" "azure_identity_binding" {
  count = var.workload_identity ? 0 : 1

  yaml_body = yamlencode(local.azure_identity_binding)

  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.azure_identity
  ]
}
