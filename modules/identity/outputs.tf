output "client_id" {
  description = "client id of user assigned identity"
  value       = azurerm_user_assigned_identity.main.client_id
}

output "name" {
  description = "name of user assigned identity"
  value       = azurerm_user_assigned_identity.main.name
}