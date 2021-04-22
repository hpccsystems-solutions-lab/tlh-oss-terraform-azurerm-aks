data "azurerm_resource_group" "parent" {
  name = var.aks_resource_group_name
}

data "azurerm_resource_group" "node" {
  name = var.aks_node_resource_group_name
}

data "http" "chart" {
  url = "https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts/index.yaml"
}

data "http" "crds" {
  url = "https://raw.githubusercontent.com/Azure/aad-pod-identity/v${local.app_version}/charts/aad-pod-identity/crds/crd.yaml"
}