data "azurerm_client_config" "current" {}

data "azurerm_kubernetes_cluster" "aks" {
  name                = module.kubernetes.name
  resource_group_name = var.resource_group_name
}