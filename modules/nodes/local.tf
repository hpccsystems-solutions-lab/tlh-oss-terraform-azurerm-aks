locals {
  vm_types = merge({
    medium     = "Standard_B2s"
    large      = "Standard_D2a_v4"
    xlarge     = "Standard_D4a_v4"
    "2xlarge"  = "Standard_D8a_v4"
    "4xlarge"  = "Standard_D16a_v4"
    "8xlarge"  = "Standard_D32a_v4"
    "12xlarge" = "Standard_D48a_v4"
    "16xlarge" = "Standard_D64a_v4"
    "24xlarge" = "Standard_D96a_v4"
  }, var.vm_types)

  spot_vm_types = merge({
    medium     = "Standard_B2s"
    large      = "Standard_D2a_v4"
    xlarge     = "Standard_D4a_v4"
    "2xlarge"  = "Standard_D8a_v4"
    "4xlarge"  = "Standard_D16a_v4"
    "8xlarge"  = "Standard_D32a_v4"
    "12xlarge" = "Standard_D48a_v4"
    "16xlarge" = "Standard_D64a_v4"
    "24xlarge" = "Standard_D96a_v4"
  }, var.spot_vm_types)

  node_pool_defaults = merge({
    availability_zones           = [1, 2, 3]
    enable_auto_scaling          = true
    enable_host_encryption       = true
    enable_node_public_ip        = false
    eviction_policy              = "Delete"
    max_count                    = 2
    max_pods                     = null
    max_surge                    = "1"
    min_count                    = 1
    mode                         = "User"
    name                         = null
    node_count                   = 1
    node_labels                  = {}
    node_taints                  = []
    only_critical_addons_enabled = false
    orchestrator_version         = null
    os_disk_size_gb              = null
    os_disk_type                 = "Managed"
    os_type                      = "Linux"
    priority                     = "Regular"
    proximity_placement_group_id = null
    spot_max_price               = "-1"
    subnet                       = null
    tags                         = {}
    type                         = "VirtualMachineScaleSets"
    vm_size                      = "Standard_B2s"
  }, var.node_pool_defaults)

  node_pool_tags = merge(var.node_pool_tags, {
    "k8s.io|cluster-autoscaler|enabled"             = "true"
    "k8s.io|cluster-autoscaler|${var.cluster_name}" = "owned"
  })

  subnet_tags = {
    public  = "${reverse(compact(split("/", var.subnets.public.id)))[2]}.${reverse(compact(split("/", var.subnets.public.id)))[0]}"
    private = "${reverse(compact(split("/", var.subnets.private.id)))[2]}.${reverse(compact(split("/", var.subnets.private.id)))[0]}"
  }


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

  default_node_pool = merge(
  {
    name                = "system"
    tier                = "standard"
    vm_size             = "medium"
    min_count           = 2
    max_count           = 3
    tags                = {}
  }, var.default_node_pool,
  {
    availability_zones = [1,2,3]
    lifecycle          = "Regular"
    os_type            = "Linux"
    subnet             = "private"
  })

  merge_pools = [ for pool in concat([local.default_node_pool], var.node_pools): merge(local.node_pool_defaults, pool) ]

  node_pools = merge(values({ for pool in local.merge_pools:
    pool.name => { for zone in(contains(local.multi_az_node_pool_tiers, pool.tier) ? var.availability_zones : [0]) :
      "${pool.name}${(zone == 0 ? "" : zone)}" => {
        vm_size     = (lower(pool.lifecycle) == "spot" ? local.spot_vm_types[pool.vm_size] : local.vm_types[pool.vm_size])
        node_taints = distinct(compact([lookup(local.node_pool_taints, pool.tier, ""), lookup(local.node_pool_taints, pool.lifecycle, "")]))
        node_labels = {
          "lnrs.io/subnet"    = (contains(local.public_tiers, pool.tier) ? local.subnet_tags.public : local.subnet_tags.private)
          "lnrs.io/tier"      = pool.tier
          "lnrs.io/lifecycle" = pool.lifecycle
          "lnrs.io/size"      = pool.vm_size
        }
        tags                  = merge(local.node_pool_tags, { "lnrs.io|tier" = pool.tier }, pool.tags)
        node_count            = (pool.enable_auto_scaling ? null : pool.node_count)
        min_count             = (pool.enable_auto_scaling ? pool.min_count : null)
        max_count             = (pool.enable_auto_scaling ? pool.max_count : null)
        availability_zones    = (zone != 0 ? [zone] : var.availability_zones)
        subnet                = (contains(local.public_tiers, pool.tier) ? "public" : "private")
        enable_node_public_ip = (pool.subnet == "public" ? true : false)
        priority              = pool.lifecycle
      }
    }
  })...)
}