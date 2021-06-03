data "azurerm_client_config" "current" {}

resource "time_sleep" "aks" {
  depends_on = [module.kubernetes]

  create_duration = "10s"
}

data "azurerm_kubernetes_cluster" "aks" {
  depends_on = [time_sleep.aks]

  name                = module.kubernetes.name
  resource_group_name = var.resource_group_name
}