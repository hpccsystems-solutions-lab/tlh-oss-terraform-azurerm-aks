module "cluster" {
  source = "./modules/cluster"

  location                       = var.location
  resource_group_name            = var.resource_group_name
  cluster_name                   = var.cluster_name
  cluster_version_full           = local.cluster_version_full
  sku_tier_paid                  = var.sku_tier_paid
  cluster_endpoint_public_access = var.cluster_endpoint_public_access
  cluster_endpoint_access_cidrs  = var.cluster_endpoint_access_cidrs
  network_plugin                 = var.network_plugin
  subnet_id                      = local.subnet_id
  route_table_id                 = local.route_table_id
  podnet_cidr_block              = var.podnet_cidr_block
  admin_group_object_ids         = var.admin_group_object_ids
  bootstrap_vm_size              = local.bootstrap_vm_size
  logging_storage_account_id     = var.logging_storage_account_id
  oms_agent                      = local.experimental_oms_agent
  oms_log_analytics_workspace_id = local.experimental_oms_log_analytics_workspace_id
  windows_support                = local.experimental_windows_support
  tags                           = local.tags
  timeouts                       = local.timeouts
  experimental                   = var.experimental
}

module "rbac" {
  source = "./modules/rbac"

  azure_env               = var.azure_env
  cluster_id              = module.cluster.id
  azuread_clusterrole_map = var.azuread_clusterrole_map
  labels                  = local.labels

  depends_on = [
    module.cluster
  ]
}

module "node_groups" {
  source = "./modules/node-groups"

  subscription_id      = local.subscription_id
  location             = var.location
  resource_group_name  = var.resource_group_name
  cluster_id           = module.cluster.id
  cluster_name         = var.cluster_name
  cluster_version_full = local.cluster_version_full
  network_plugin       = var.network_plugin
  subnet_id            = local.subnet_id
  availability_zones   = local.availability_zones
  node_group_templates = var.node_group_templates
  bootstrap_vm_size    = local.bootstrap_vm_size
  azure_auth_env       = local.azure_auth_env
  labels               = local.labels
  tags                 = local.tags
  experimental         = var.experimental

  depends_on = [
    module.cluster
  ]
}

module "core_config" {
  source = "./modules/core-config"

  azure_env           = var.azure_env
  tenant_id           = local.tenant_id
  subscription_id     = local.subscription_id
  location            = var.location
  resource_group_name = var.resource_group_name

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  network_plugin  = var.network_plugin

  subnet_name        = var.subnet_name
  availability_zones = local.availability_zones

  kubelet_identity_id      = module.cluster.kubelet_identity.object_id
  node_resource_group_name = module.cluster.node_resource_group_name

  dns_resource_group_lookup = var.dns_resource_group_lookup

  core_services_config = var.core_services_config

  control_plane_log_analytics_workspace_id = module.cluster.control_plane_log_analytics_workspace_id
  oms_agent                                = local.experimental_oms_agent
  oms_log_analytics_workspace_id           = local.experimental_oms_log_analytics_workspace_id

  labels = local.labels
  tags   = local.tags

  experimental = var.experimental

  depends_on = [
    module.rbac,
    module.node_groups
  ]
}

resource "kubernetes_config_map" "default" {
  metadata {
    name      = "tfmodule-${local.module_name}"
    namespace = "kube-system"

    labels = local.labels
  }

  data = {
    version = local.module_version

    config = jsonencode({
      cluster = {
        name    = var.cluster_name
        version = local.cluster_version_full
      }
    })
  }

  depends_on = [
    module.core_config
  ]
}
