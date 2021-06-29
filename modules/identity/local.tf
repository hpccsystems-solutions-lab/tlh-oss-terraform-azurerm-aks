locals {
  identity = {
    apiVersion = "aadpodidentity.k8s.io/v1"
    kind       = "AzureIdentity"
    metadata = {
      name      = azurerm_user_assigned_identity.main.name	
      namespace = var.namespace
    }
    spec = {
      type       = 0
      resourceId = azurerm_user_assigned_identity.main.id
      clientId   = azurerm_user_assigned_identity.main.client_id
    }
  }

  identity_binding = {
    apiVersion = "aadpodidentity.k8s.io/v1"
    kind       = "AzureIdentityBinding"
    metadata = {
      name      = "${azurerm_user_assigned_identity.main.name}-binding"
      namespace = var.namespace
    }
    spec = {
      azureIdentity = azurerm_user_assigned_identity.main.name
      selector      = azurerm_user_assigned_identity.main.name
    }
  }
}
