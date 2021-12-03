resource "random_string" "control-plane-law" {
  length           = 5
  special          = false
  lower            = true
  upper            = false
}

resource "azurerm_log_analytics_workspace" "control-plane-law" {
  name                     = "aks-control-plane-logs-${random_string.control-plane-law.id}"
  resource_group_name      = var.resource_group_name
  location                 = var.resource_group_location
  retention_in_days        = 30
  tags                     = merge(var.tags, {"description" = "control-plane-logs", cluster-name = var.cluster_name})
}
