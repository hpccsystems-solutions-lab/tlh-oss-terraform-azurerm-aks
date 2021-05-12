#data "azurerm_dns_zone" "dns_zone" {
#  name                = var.dns_zones.name
#  resource_group_name = var.dns_zones.resource_group_name
#}

data "azurerm_dns_zone" "dns_zone" {
  for_each = toset(var.dns_zones.names)

  name                = each.value
  resource_group_name = var.dns_zones.resource_group_name
}

data "azurerm_resource_group" "dns_zone" {
  name                = var.dns_zones.resource_group_name
}

data "azurerm_resource_group" "cluster" {
  name                = var.resource_group_name
}