data "azurerm_dns_zone" "dns_zone" {
  for_each = var.dns_zones

  name                = each.key
  resource_group_name = each.value
}

data "azurerm_resource_group" "dns_zone" {
  for_each = var.dns_zones

  name = each.value
}

data "azurerm_resource_group" "cluster" {
  name                = var.resource_group_name
}