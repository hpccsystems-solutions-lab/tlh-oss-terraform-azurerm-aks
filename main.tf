module "nodes" {
  source = "./modules/nodes"

  cluster_name = local.cluster_name
  subnets      = {
      private = var.virtual_network.subnets.private
      public  = var.virtual_network.subnets.public
  }

  enable_host_encryption = var.enable_host_encryption

  node_pool_defaults = var.node_pool_defaults
  node_pool_taints   = var.node_pool_taints
  node_pool_tags     = merge(var.tags, var.node_pool_tags)
  node_pools         = var.node_pools
}

module "kubernetes" {
  source = "github.com/Azure-Terraform/terraform-azurerm-kubernetes.git?ref=v4.0.0"

  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  cluster_name = local.cluster_name
  dns_prefix   = local.cluster_name

  kubernetes_version = local.cluster_patch_version

  network_plugin          = local.network_plugin
  pod_cidr                = (local.network_plugin == "kubenet" ? var.pod_cidr : null)
  network_profile_options = local.network_profile_options

  virtual_network = {
    subnets = {
      private = var.virtual_network.subnets.private
      public  = var.virtual_network.subnets.public
    }
    route_table_id = var.virtual_network.route_table_id
  }

  node_pools             = module.nodes.node_pools
  default_node_pool      = module.nodes.default_node_pool

  rbac = {
    enabled        = true
    ad_integration = true
  }

  windows_profile = (module.nodes.windows_config.enabled ? {
    admin_username = module.nodes.windows_config.admin_username
    admin_password = module.nodes.windows_config.admin_password
  } : null)
}

module "core-config" {
  depends_on = [module.kubernetes]

  source = "./modules/core-config"
  
  resource_group_name = var.resource_group_name
  location            = var.location

  cluster_name        = module.kubernetes.name
  cluster_id          = module.kubernetes.id
  cluster_version     = var.cluster_version

  azuread_clusterrole_map     = var.azuread_clusterrole_map

  additional_priority_classes = var.additional_priority_classes
  additional_storage_classes  = var.additional_storage_classes

  aks_identity                 = module.kubernetes.kubelet_identity.object_id
  aks_node_resource_group_name = module.kubernetes.node_resource_group
  network_plugin               = local.network_plugin

  azure_tenant_id       = data.azurerm_client_config.current.tenant_id
  azure_subscription_id = data.azurerm_client_config.current.subscription_id

  namespaces = var.namespaces
  configmaps = var.configmaps
  secrets    = var.secrets
  config     = var.config

  external_dns_zones      = var.external_dns_zones

  tags = var.tags
}
