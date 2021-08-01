locals {
  vm_types = {
    x64-gp = {
      medium     = "Standard_B2s"
      large      = "Standard_D2s_v4"
      xlarge     = "Standard_D4s_v4"
      "2xlarge"  = "Standard_D8s_v4"
      "4xlarge"  = "Standard_D16s_v4"
      "8xlarge"  = "Standard_D32s_v4"
      "12xlarge" = "Standard_D48s_v4"
      "16xlarge" = "Standard_D64s_v4"
      "24xlarge" = "Standard_D96as_v4"
    }
  }

  spot_vm_types = {
    x64-gp = {
      medium     = "Standard_B2s"
      large      = "Standard_D2s_v4"
      xlarge     = "Standard_D4s_v4"
      "2xlarge"  = "Standard_D8s_v4"
      "4xlarge"  = "Standard_D16s_v4"
      "8xlarge"  = "Standard_D32s_v4"
      "12xlarge" = "Standard_D48s_v4"
      "16xlarge" = "Standard_D64s_v4"
      "24xlarge" = "Standard_D96as_v4"
    }
  }

  node_pool_defaults = merge({
    availability_zones   = [1, 2, 3]
    enable_auto_scaling  = true
    max_pods             = null
    max_surge            = "1"
    orchestrator_version = var.orchestrator_version
    },
    var.node_pool_defaults,
    { # These default settings cannot be overridden
      priority                     = "Regular"
      type                         = "VirtualMachineScaleSets"
      enable_host_encryption       = true
      eviction_policy              = null
      proximity_placement_group_id = null
      spot_max_price               = null
      os_disk_size_gb              = null
      os_disk_type                 = "Managed"
      only_critical_addons_enabled = false
    },
    { # These settings are determinted by the node pool inputs
      node_count            = null
      min_count             = null
      max_count             = null
      node_taints           = null
      node_labels           = null
      tags                  = null
      subnet                = null
      enable_node_public_ip = null
      mode                  = null
  })

  tags = merge(var.tags, {
    "k8s.io|cluster-autoscaler|enabled"             = "true"
    "k8s.io|cluster-autoscaler|${var.cluster_name}" = "owned"
  })

  taint_effects = {
    "NO_SCHEDULE"        = "NoSchedule"
    "NO_EXECUTE"         = "NoExecute"
    "PREFER_NO_SCHEDULE" = "PreferNoSchedule"
  }

  system_node_pool = {
    name         = "system"
    single_vmss  = false
    public       = false
    node_type    = "x64-gp"
    node_size    = "large"
    min_capacity = 1
    max_capacity = 2
    subnet       = "private"
    labels       = {}
    taints       = [
      {
        key = "CriticalAddonsOnly"
        value = true
        effect = "NO_SCHEDULE"
      }
    ]
    tags         = {}
  }

  node_pools = merge(values({ for pool in concat([local.system_node_pool], var.node_pools) :
    pool.name => { for zone in (pool.single_vmss ? [0] : local.node_pool_defaults.availability_zones) :
      "${pool.name}${(zone == 0 ? "" : zone)}" => merge(local.node_pool_defaults, {
        availability_zones = (zone != 0 ? [zone] : local.node_pool_defaults.availability_zones)
        priority           = (lookup(pool, "use_spot", false) ? "Spot" : "Regular")
        vm_size            = local.vm_types[regex("[0-9A-Za-z]+-[0-9A-Za-z]+", pool.node_type)][pool.node_size]
        os_type            = ((length(regexall("-win", pool.node_type)) > 0) ? "Windows" : "Linux")
        min_count          = pool.min_capacity
        max_count          = pool.max_capacity

        node_labels = merge({
          "lnrs.io/lifecycle" = (lookup(pool, "use_spot", false) ? "spot" : "ondemand")
          "lnrs.io/size"      = pool.node_size
        }, pool.labels)
        node_taints = [ for taint in pool.taints:
              "${taint.key}=${taint.value}:${lookup(local.taint_effects, taint.effect, taint.effect)}"
        ]
        tags        = merge(local.tags, pool.tags)

        subnet                       = (pool.public ? "public" : "private")
        enable_node_public_ip        = (pool.public ? true : false)

        mode                         = (pool.name == local.system_node_pool.name ? "System" : "User")
        only_critical_addons_enabled = ((pool.name == local.system_node_pool.name && zone == 1) ? true : false)
      })
    }
  })...)

  windows_nodes = (length([for v in local.node_pools : v if lower(v.os_type) == "windows"]) > 0 ? true : false)

}