resource "azurerm_kubernetes_cluster_node_pool" "default" {
  name = var.name

  kubernetes_cluster_id = var.cluster_id
  orchestrator_version  = var.cluster_version_full

  vnet_subnet_id = var.subnet_id
  zones          = var.availability_zones

  mode            = var.system ? "System" : "User"
  scale_down_mode = "Delete"

  priority            = "Regular"
  enable_auto_scaling = local.enable_auto_scaling
  node_count          = local.enable_auto_scaling ? null : var.max_capacity
  min_count           = local.enable_auto_scaling ? var.min_capacity : null
  max_count           = local.enable_auto_scaling ? var.max_capacity : null

  upgrade_settings {
    max_surge = 1
  }

  os_type = local.os_types[var.node_os]
  os_sku  = local.os_skus[var.node_os]

  vm_size                = local.vm_size_lookup["${var.node_arch}_${var.node_type}_${var.node_type_variant}_${var.node_type_version}"][var.node_size]
  os_disk_type           = "Managed"
  os_disk_size_gb        = 128
  enable_host_encryption = true
  enable_node_public_ip  = false

  ultra_ssd_enabled = var.ultra_ssd

  proximity_placement_group_id = var.proximity_placement_group_id

  max_pods = var.network_plugin == "azure" && var.max_pods != -1 ? var.max_pods : local.max_pods[var.network_plugin]

  fips_enabled = var.fips

  node_labels = merge(local.vm_labels[var.node_type], { "lnrs.io/lifecycle" = "ondemand", "lnrs.io/size" = var.node_size }, var.labels)
  node_taints = [for taint in concat(local.vm_taints[var.node_type], var.taints) : "${taint.key}=${taint.value}:${local.taint_effects[taint.effect]}"]

  dynamic "linux_os_config" {
    for_each = var.node_os == "ubuntu" && length(var.os_config.sysctl) > 0 ? ["default"] : []

    content {

      sysctl_config {
        net_core_rmem_max           = lookup(var.os_config.sysctl, "net_core_rmem_max", null)
        net_core_wmem_max           = lookup(var.os_config.sysctl, "net_core_wmem_max", null)
        net_ipv4_tcp_keepalive_time = lookup(var.os_config.sysctl, "net_ipv4_tcp_keepalive_time", null)
      }
    }
  }

  tags = var.tags

  timeouts {
    create = format("%vm", var.timeouts.node_group_create / 60)
    read   = format("%vm", var.timeouts.node_group_read / 60)
    update = format("%vm", var.timeouts.node_group_update / 60)
    delete = format("%vm", var.timeouts.node_group_delete / 60)
  }
}
