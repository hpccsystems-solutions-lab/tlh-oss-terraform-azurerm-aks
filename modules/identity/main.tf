resource "azurerm_user_assigned_identity" "main" {
  name                = "${var.cluster_name}-${var.identity_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "main" {
  #for_each = var.roles
  count = length(var.roles)

  scope              = var.roles[count.index].scope
  role_definition_id = var.roles[count.index].role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.main.principal_id
  #scope              = each.value.scope
  #role_definition_id = each.value.role_definition_resource_id
  #principal_id       = azurerm_user_assigned_identity.main.principal_id
}

resource "helm_release" "main" {
  name  = "pod-id-${var.identity_name}"
  chart = "${path.module}/chart"

  namespace = var.namespace

  values = [<<-EOT
  namespace: "${var.namespace}"
  azureIdentity:
    name: "${azurerm_user_assigned_identity.main.name}"
    type: 0
    resourceID: "${azurerm_user_assigned_identity.main.id}"
    clientID: "${azurerm_user_assigned_identity.main.client_id}"
  
  azureIdentityBinding:
    name: "${azurerm_user_assigned_identity.main.name}-binding"
    selector: "${azurerm_user_assigned_identity.main.name}"
  EOT
  ]
}