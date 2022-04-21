data "azurerm_subscription" "current" {
}

data "azurerm_client_config" "current" {
}

locals {
  module_name    = "terraform-azurerm-aks"
  module_version = "v1.0.0-beta"

  # az aks get-versions --location eastus --output table
  cluster_full_versions = {
    # "1.22" = "1.22.6"
    "1.21" = "1.21.9"
  }

  availability_zones = [1, 2, 3]

  bootstrap_vm_size = "Standard_B2s"

  cluster_version_full = local.cluster_full_versions[var.cluster_version]

  tenant_id       = data.azurerm_subscription.current.tenant_id
  subscription_id = data.azurerm_subscription.current.subscription_id
  client_id       = data.azurerm_client_config.current.client_id

  virtual_network_resource_group_id = "/subscriptions/${local.subscription_id}/resourceGroups/${var.virtual_network_resource_group_name}"
  virtual_network_id                = "${local.virtual_network_resource_group_id}/providers/Microsoft.Network/virtualNetworks/${var.virtual_network_name}"
  subnet_id                         = "${local.virtual_network_id}/subnets/${var.subnet_name}"
  route_table_id                    = "${local.virtual_network_resource_group_id}/providers/Microsoft.Network/routeTables/${var.route_table_name}"

  labels = {
    "lnrs.io/k8s-platform" = "true"
  }

  tags = merge(var.tags, {
    "lnrs.io_terraform"                         = "true"
    "lnrs.io_terraform-module"                  = local.module_name
    "kubernetes.io_cluster_${var.cluster_name}" = "owned"
    "lnrs.io_k8s-platform"                      = "true"
  })

  azure_auth_env = merge({
    AZURE_TENANT_ID       = local.tenant_id
    AZURE_SUBSCRIPTION_ID = local.subscription_id
    AZURE_CLIENT_ID       = local.client_id
  }, var.azure_auth_env)

  experimental_oms_agent                      = lookup(var.experimental, "oms_agent", false)
  experimental_oms_log_analytics_workspace_id = lookup(var.experimental, "oms_log_analytics_workspace_id", "")
  experimental_windows_support                = lookup(var.experimental, "windows_support", false)
}
