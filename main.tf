module "nodes" {
  source = "./modules/nodes"

  cluster_name        = local.cluster_name
  network_plugin      = var.network_plugin
  subnets             = var.subnets

  node_pool_defaults  = var.node_pool_defaults
  node_pool_taints    = var.node_pool_taints
  node_pool_tags      = merge(var.tags, var.node_pool_tags)
  node_pools          = var.node_pools
}

module "kubernetes" {
  source = "github.com/Azure-Terraform/terraform-azurerm-kubernetes.git?ref=v3.0.2"

  location                 = var.location
  tags                     = var.tags
  resource_group_name      = var.resource_group_name
  
  cluster_name = local.cluster_name
  dns_prefix   = local.cluster_name

  network_plugin = var.network_plugin

  node_pool_subnets  = var.subnets
  node_pools         = module.nodes.node_pools
  default_node_pool  = module.nodes.default_node_pool
}