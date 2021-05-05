data "azurerm_dns_zone" "dns_zone" {
  name                = var.dns_zone.name
  resource_group_name = var.dns_zone.resource_group_name
}