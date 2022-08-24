resource "azurerm_storage_account" "data" {
  name                = "${replace(var.cluster_name, "-", "")}data"
  resource_group_name = var.resource_group_name
  location            = var.location

  account_tier             = "Standard"
  account_replication_type = "ZRS"

  min_tls_version = "TLS1_2"

  tags = var.tags
}
