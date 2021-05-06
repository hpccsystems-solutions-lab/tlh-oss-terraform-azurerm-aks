data "azurerm_resource_group" "cluster" {
  name = var.resource_group_name
}

data "azurerm_resource_group" "dns_zone" {
  name = var.dns_zone.resource_group_name
}