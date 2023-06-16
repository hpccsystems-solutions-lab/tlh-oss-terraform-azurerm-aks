resource "azurerm_proximity_placement_group" "default" {
  for_each = toset(local.placement_group_names)

  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

module "system_node_groups" {
  source   = "./modules/node-group"
  for_each = local.system_node_groups

  name                         = each.key
  cluster_id                   = var.cluster_id
  cluster_version              = var.cluster_version
  cluster_version_full         = var.cluster_version_full
  cluster_patch_upgrade        = var.cluster_patch_upgrade
  cni                          = var.cni
  fips                         = var.fips
  subnet_id                    = var.subnet_id
  availability_zones           = each.value.availability_zones
  system                       = true
  node_arch                    = each.value.node_arch
  node_os                      = each.value.node_os
  node_type                    = each.value.node_type
  node_type_variant            = each.value.node_type_variant
  node_type_version            = each.value.node_type_version
  node_size                    = each.value.node_size
  min_capacity                 = each.value.min_capacity
  max_capacity                 = each.value.max_capacity
  os_config                    = each.value.os_config
  ultra_ssd                    = each.value.ultra_ssd
  os_disk_size                 = each.value.os_disk_size
  temp_disk_mode               = each.value.temp_disk_mode
  nvme_mode                    = each.value.nvme_mode
  proximity_placement_group_id = each.value.proximity_placement_group_id
  max_pods                     = each.value.max_pods
  max_surge                    = each.value.max_surge
  labels                       = merge(var.labels, each.value.labels)
  taints                       = each.value.taints
  tags                         = merge(var.tags, each.value.tags)
  timeouts                     = var.timeouts
}

module "bootstrap_node_group_hack" {
  source = "./modules/bootstrap-node-group-hack"

  subscription_id     = var.subscription_id
  resource_group_name = var.resource_group_name
  cluster_name        = var.cluster_name
  fips                = var.fips
  subnet_id           = var.subnet_id
  bootstrap_name      = var.bootstrap_name
  bootstrap_vm_size   = var.bootstrap_vm_size

  depends_on = [
    module.system_node_groups
  ]
}

module "user_node_groups" {
  source   = "./modules/node-group"
  for_each = local.user_node_groups

  name                         = each.key
  cluster_id                   = var.cluster_id
  cluster_version              = var.cluster_version
  cluster_version_full         = var.cluster_version_full
  cluster_patch_upgrade        = var.cluster_patch_upgrade
  cni                          = var.cni
  fips                         = var.fips
  subnet_id                    = var.subnet_id
  availability_zones           = each.value.availability_zones
  system                       = false
  node_arch                    = each.value.node_arch
  node_os                      = each.value.node_os
  node_type                    = each.value.node_type
  node_type_variant            = each.value.node_type_variant
  node_type_version            = each.value.node_type_version
  node_size                    = each.value.node_size
  min_capacity                 = each.value.min_capacity
  max_capacity                 = each.value.max_capacity
  os_config                    = each.value.os_config
  ultra_ssd                    = each.value.ultra_ssd
  os_disk_size                 = each.value.os_disk_size
  temp_disk_mode               = each.value.temp_disk_mode
  nvme_mode                    = each.value.nvme_mode
  proximity_placement_group_id = each.value.proximity_placement_group_id
  max_pods                     = each.value.max_pods
  max_surge                    = each.value.max_surge
  labels                       = merge(var.labels, each.value.labels)
  taints                       = each.value.taints
  tags                         = merge(var.tags, each.value.tags)
  timeouts                     = var.timeouts

  depends_on = [
    module.bootstrap_node_group_hack
  ]
}
