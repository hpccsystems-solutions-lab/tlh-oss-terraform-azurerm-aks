data "azurerm_resource_group" "parent" {
  name = var.aks_resource_group_name
}

data "azurerm_resource_group" "node" {
  name = var.aks_node_resource_group_name
}