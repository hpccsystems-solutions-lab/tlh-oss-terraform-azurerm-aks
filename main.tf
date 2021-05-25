module "nodes" {
  source = "./modules/nodes"

  cluster_name = local.cluster_name
  subnets      = var.subnets

  enable_host_encryption = var.enable_host_encryption

  node_pool_defaults = var.node_pool_defaults
  node_pool_taints   = var.node_pool_taints
  node_pool_tags     = merge(var.tags, var.node_pool_tags)
  node_pools         = var.node_pools
}

module "kubernetes" {
  source = "github.com/Azure-Terraform/terraform-azurerm-kubernetes.git?ref=v3.2.4"

  location            = var.location
  tags                = var.tags
  resource_group_name = var.resource_group_name

  cluster_name = local.cluster_name
  dns_prefix   = local.cluster_name

  kubernetes_version = local.cluster_version

  network_plugin          = local.network_plugin
  pod_cidr                = (local.network_plugin == "kubenet" ? var.pod_cidr : null)
  network_profile_options = var.network_profile_options

  node_pool_subnets          = var.subnets
  custom_route_table_ids     = var.custom_route_table_ids
  configure_subnet_nsg_rules = false

  node_pools             = module.nodes.node_pools
  default_node_pool      = module.nodes.default_node_pool

  rbac = {
    enabled        = true
    ad_integration = true
  }

  rbac_admin_object_ids = var.rbac_admin_object_ids

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

  cluster_name          = module.kubernetes.name
  cluster_id            = module.kubernetes.id

  azuread_k8s_role_map  = var.azuread_k8s_role_map

  additional_priority_classes = var.additional_priority_classes
  additional_storage_classes = var.additional_storage_classes

  aks_identity                 = module.kubernetes.kubelet_identity.object_id
  aks_node_resource_group_name = module.kubernetes.node_resource_group
  network_plugin               = local.network_plugin

  azure_tenant_id       = data.azurerm_client_config.current.tenant_id
  azure_subscription_id = data.azurerm_client_config.current.subscription_id

  namespaces = var.namespaces
  configmaps = var.configmaps
  secrets    = var.secrets

  external_dns_zones      = var.external_dns_zones
  cert_manager_dns_zones  = var.cert_manager_dns_zones
  letsencrypt_environment = var.letsencrypt_environment
  letsencrypt_email       = var.letsencrypt_email

  tags = var.tags
}
