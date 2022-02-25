resource "random_password" "windows_admin_username" {
  count   = (local.windows_nodes ? 1 : 0)
  length  = 8
  special = false
  number  = false
}

resource "random_password" "windows_admin_password" {
  count   = (local.windows_nodes ? 1 : 0)
  length  = 14
  special = true
}

resource "azurerm_proximity_placement_group" "default" {
  for_each = toset(local.placement_group_names)

  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}
