locals {
  vm_types = merge({
    medium     = "Standard_B2s"
    large      = "Standard_D2s_v4"
    xlarge     = "Standard_D4s_v4"
    "2xlarge"  = "Standard_D8s_v4"
    "4xlarge"  = "Standard_D16s_v4"
    "8xlarge"  = "Standard_D32s_v4"
    "12xlarge" = "Standard_D48s_v4"
    "16xlarge" = "Standard_D64s_v4"
    "24xlarge" = "Standard_D96as_v4"
  }, var.vm_types)

  node_pool_defaults = merge({
    availability_zones   = [1, 2, 3]
    enable_auto_scaling  = true
    max_pods             = null
    max_surge            = "1"
    orchestrator_version = null
    },
    var.node_pool_defaults,
    { # These default settings cannot be overridden
      priority                     = "Regular"
      type                         = "VirtualMachineScaleSets"
      eviction_policy              = null
      enable_host_encryption       = true
      proximity_placement_group_id = null
      spot_max_price               = null
      os_disk_size_gb              = null
      os_disk_type                 = "Managed"
      only_critical_addons_enabled = false
    },
    { # These settings are determinted by the node pool inputs
      vm_size               = null
      os_type               = null
      node_taints           = null
      node_labels           = null
      tags                  = null
      node_count            = null
      min_count             = null
      max_count             = null
      subnet                = null
      enable_node_public_ip = null
      mode                  = null
  })

  node_pool_tags = merge(var.node_pool_tags, {
    "k8s.io|cluster-autoscaler|enabled"             = "true"
    "k8s.io|cluster-autoscaler|${var.cluster_name}" = "owned"
  })

  node_pool_taints = merge({
    ingress = "ingress=true:NoSchedule"
    egress  = "egress=true:NoSchedule"
  }, var.node_pool_taints)

  multi_az_node_pool_tiers = [
    "ingress",
    "egress"
  ]

  public_tiers = [
    "ingress",
    "egress"
  ]

  default_node_pool = {
    name      = "system"
    tier      = "standard"
    lifecycle = "normal"
    vm_size   = "medium"
    os_type   = "Linux"
    subnet    = "private"
    min_count = 2
    max_count = 3
    tags      = {}
  }

  node_pools = merge(values({ for pool in concat([local.default_node_pool], var.node_pools) :
    pool.name => { for zone in(contains(local.multi_az_node_pool_tiers, pool.tier) ? local.node_pool_defaults.availability_zones : [0]) :
      "${pool.name}${(zone == 0 ? "" : zone)}" => merge(local.node_pool_defaults, {
        vm_size     = local.vm_types[pool.vm_size]
        os_type     = pool.os_type
        node_taints = compact(split(",", local.node_pool_taints, pool.tier, "")))
        node_labels = {
          "lnrs.io/tier"      = pool.tier
          "lnrs.io/lifecycle" = "normal"
          "lnrs.io/size"      = pool.vm_size
        }
        tags                         = merge(local.node_pool_tags, { "lnrs.io|tier" = pool.tier }, pool.tags)
        min_count                    = pool.min_count
        max_count                    = pool.max_count
        availability_zones           = (zone != 0 ? [zone] : local.node_pool_defaults.availability_zones)
        subnet                       = (contains(local.public_tiers, pool.tier) ? "public" : "private")
        enable_node_public_ip        = (contains(local.public_tiers, pool.tier) ? true : false)
        priority                     = (pool.lifecycle == "normal" ? "Regular" : null)
        mode                         = (pool.name == local.default_node_pool.name ? "System" : "User")
        only_critical_addons_enabled = (pool.name == local.default_node_pool ? true : false)
      })
    }
  })...)

  windows_nodes = (length([for v in local.node_pools : v if lower(v.os_type) == "windows"]) > 0 ? true : false)

}