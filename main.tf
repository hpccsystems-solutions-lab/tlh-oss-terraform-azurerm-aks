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

  node_pool_subnets      = var.subnets
  custom_route_table_ids = var.custom_route_table_ids
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

module "pod_identity" {
  source = "./modules/pod-identity"

  depends_on = [module.kubernetes]

  aks_identity                 = module.kubernetes.kubelet_identity.object_id
  aks_resource_group_name      = var.resource_group_name
  aks_node_resource_group_name = module.kubernetes.node_resource_group
  network_plugin               = local.network_plugin
}

provider "helm" {
  kubernetes {
    host                   = module.kubernetes.kube_config.host
    client_certificate     = base64decode(module.kubernetes.kube_config.client_certificate)
    client_key             = base64decode(module.kubernetes.kube_config.client_key)
    cluster_ca_certificate = base64decode(module.kubernetes.kube_config.cluster_ca_certificate)
  }
}

module "priority_classes" {
  source = "./modules/priority-classes"

  additional_priority_classes = var.additional_priority_classes
}

module "storage_classes" {
  source = "./modules/storage-classes"

  additional_storage_classes = var.additional_storage_classes
}

module "external_dns" {
  source = "./modules/external-dns"

  azure_tenant_id       = data.azurerm_client_config.current.tenant_id
  azure_subscription_id = data.azurerm_client_config.current.subscription_id

  resource_group_name          = var.resource_group_name
  cluster_name                 = module.kubernetes.name
  dns_zone_resource_group_name = var.dns_zone_resource_group_name
  dns_zone_name                = var.dns_zone_name

  tags = var.tags
}

module "core-config" {
  source = "./modules/core-config"

  namespaces = var.namespaces
  configmaps = var.configmaps
  secrets    = var.secrets
}
