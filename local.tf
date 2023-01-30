data "azurerm_subscription" "current" {
}

# data "azurerm_client_config" "current" {
# }

locals {
  module_name    = "terraform-azurerm-aks"
  module_version = "v1.6.0-beta.1"

  cluster_tags = {
    "lnrs.io_terraform-module-version" = local.module_version
  }

  # az aks get-versions --location eastus --output table
  # az aks get-versions --location westeurope --output table
  # https://releases.aks.azure.com/webpage/index.html
  cluster_full_versions = merge({
    "1.24" = "1.24.6"
    "1.23" = "1.23.12"
  }, var.experimental.v1_25 ? { "1.25" = "1.25.2" } : {})

  availability_zones = [1, 2, 3]

  bootstrap_name    = "bootstrap"
  bootstrap_vm_size = "Standard_B2s"

  cluster_version_full = local.cluster_full_versions[var.cluster_version]

  tenant_id       = data.azurerm_subscription.current.tenant_id
  subscription_id = data.azurerm_subscription.current.subscription_id
  # client_id       = data.azurerm_client_config.current.client_id

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

  # Timeouts are in seconds for compatibility with all use cases and must be converted to string format to support Terraform resource timeout blocks
  # https://www.terraform.io/language/resources/syntax#operation-timeouts
  timeouts = {
    cluster_read   = 300
    cluster_modify = 5400
    helm_modify    = 600
  }
}
