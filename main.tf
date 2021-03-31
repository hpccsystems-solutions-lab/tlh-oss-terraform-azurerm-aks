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
  source = "github.com/Azure-Terraform/terraform-azurerm-kubernetes.git?ref=v3.0.4"

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

provider "kubernetes" {
  host                   = module.kubernetes.kube_config.host
  client_certificate     = base64decode(module.kubernetes.kube_config.client_certificate)
  client_key             = base64decode(module.kubernetes.kube_config.client_key)
  cluster_ca_certificate = base64decode(module.kubernetes.kube_config.cluster_ca_certificate)
}

module "priority_classes" {
  source = "github.com/LexisNexis-RBA/terraform-kubernetes-priority-class.git?ref=v0.2.0"

  additional_priority_classes = var.additional_priority_classes
}

module "storage_classes" {
  source = "./modules/storage-classes"

  additional_storage_classes = var.additional_storage_classes
}