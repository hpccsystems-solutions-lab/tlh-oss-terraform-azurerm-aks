module "nodes" {
  source = "./modules/nodes"

  cluster_name   = local.cluster_name
  subnets        = var.subnets

  node_pool_defaults = var.node_pool_defaults
  node_pool_taints   = var.node_pool_taints
  node_pool_tags     = merge(var.tags, var.node_pool_tags)
  node_pools         = var.node_pools
}

module "kubernetes" {
  source = "github.com/Azure-Terraform/terraform-azurerm-kubernetes.git?ref=v3.0.3"

  location            = var.location
  tags                = var.tags
  resource_group_name = var.resource_group_name

  cluster_name = local.cluster_name
  dns_prefix   = local.cluster_name

  kubernetes_version = local.cluster_version

  network_plugin = var.network_plugin

  node_pool_subnets = var.subnets
  node_pools        = module.nodes.node_pools
  default_node_pool = module.nodes.default_node_pool

  windows_profile = (module.nodes.windows_config.enabled ? {
    admin_username = module.nodes.windows_config.admin_username
    admin_password = module.nodes.windows_config.admin_password
  } : null)
}

module "pod_identity" {
  source = "github.com/Azure-Terraform/terraform-azurerm-kubernetes-aad-pod-identity.git?ref=v2.0.1"

  helm_chart_version = "3.0.3"

  enable_kubenet_plugin = (lower(var.network_plugin) == "kubenet" ? true : false)

  aks_node_resource_group = module.kubernetes.node_resource_group
  additional_scopes       = {
    parent_rg = data.azurerm_resource_group.parent.id
  }

  aks_identity = module.kubernetes.kubelet_identity.object_id
}