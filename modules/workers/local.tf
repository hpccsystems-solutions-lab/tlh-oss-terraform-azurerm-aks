locals {
  subnet_groups = {
    private = [for x in var.subnets : x.id if x.group == "private"]
    public  = [for x in var.subnets : x.id if x.group == "public"]
  }

  instance_types = merge({
    medium     = "Standard_B2s"
    large      = "Standard_D2a_v4"
    xlarge     = "Standard_D4a_v4"
    "2xlarge"  = "Standard_D8a_v4"
    "4xlarge"  = "Standard_D16a_v4"
    "8xlarge"  = "Standard_D32a_v4"
    "12xlarge" = "Standard_D48a_v4"
    "16xlarge" = "Standard_D64a_v4"
    "24xlarge" = "Standard_D96a_v4"
  }, var.instance_types)

  spot_instance_types = merge({
    medium     = ["Standard_B2s"]
    large      = ["Standard_D2a_v4", "Standard_D2_v4"]
    xlarge     = ["Standard_D4a_v4", "Standard_D4_v4"]
    "2xlarge"  = ["Standard_D8a_v4", "Standard_D8_v4"]
    "4xlarge"  = ["Standard_D16a_v4", "Standard_D16_v4"]
    "8xlarge"  = ["Standard_D32a_v4", "Standard_D32_v4"]
    "12xlarge" = ["Standard_D48a_v4", "Standard_D48_v4"]
    "16xlarge" = ["Standard_D64a_v4", "Standard_D64_v4"]
    "24xlarge" = ["Standard_D96a_v4"]
  }, var.spot_instance_types)

  instance_eni_count = merge({
    medium     = 3
    large      = 2
    xlarge     = 4
    "2xlarge"  = 8
    "4xlarge"  = 8
    "8xlarge"  = 8
    "12xlarge" = 8
    "16xlarge" = 8
    "24xlarge" = 8
  }, var.instance_eni_count)

  ips_per_eni = merge({
    medium     = 256
    large      = 256
    xlarge     = 256
    "2xlarge"  = 256
    "4xlarge"  = 256
    "8xlarge"  = 256
    "12xlarge" = 256
    "16xlarge" = 256
    "24xlarge" = 256
  }, var.ips_per_eni)

  worker_group_defaults = merge(var.worker_group_defaults, {
    availability_zones           = [1, 2, 3]
    enable_auto_scaling          = false
    enable_host_encryption       = true
    enable_node_public_ip        = false
    eviction_policy              = null
    max_count                    = null
    max_pods                     = null
    max_surge                    = "1"
    min_count                    = null
    mode                         = "User"
    name                         = null
    node_count                   = 1
    node_labels                  = null
    node_taints                  = null
    only_critical_addons_enabled = false
    orchestrator_version         = null
    os_disk_size_gb              = null
    os_disk_type                 = "Managed"
    os_type                      = "Linux"
    priority                     = "Regular"
    proximity_placement_group_id = null
    spot_max_price               = null
    subnet                       = null
    tags                         = null
    type                         = "VirtualMachineScaleSets"
    vm_size                      = "Standard_B2s"
  })

  worker_groups_tags = merge(var.worker_group_tags, {
    "k8s.io/cluster-autoscaler/enabled"             = "true"
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
  })

  worker_group_taints = merge({
    ingress = "ingress=true:NoSchedule"
    egress  = "egress=true:NoSchedule"
  }, var.worker_group_taints)

  multi_az_worker_group_tiers = [
    "ingress",
    "egress"
  ]

  public_tiers = [
    "ingress",
    "egress"
  ]

  system_worker_group = {
    system = {
      tier     = "standard"
      subnet   = "private"
      tags     = merge(local.worker_groups_tags, {})
      vm_size  = local.instance_types[var.default_node_pool.instance_size]
      max_pods = (((local.instance_eni_count[var.default_node_pool.instance_size] - 1) * (local.ips_per_eni[var.default_node_pool.instance_size] - 1)) + 2)
      labels = {
        "lnrs.io/subnet"    = local.subnet_groups.private[0]
        "lnrs.io/tier"      = "standard"
        "lnrs.io/lifecycle" = "normal"
        "lnrs.io/size"      = var.default_node_pool.instance_size
      }
      taints             = join(",", distinct(compact([lookup(local.worker_group_taints, "standard", ""), lookup(local.worker_group_taints, "normal", "")])))
      tags               = merge(local.worker_groups_tags, {})
      node_count         = var.default_node_pool.instance_count
      availability_zones = [1, 2, 3]
    }
  }

  worker_groups = merge(values({ for group in var.worker_groups :
    group.name => { for zone in(contains(local.multi_az_worker_group_tiers, group.tier) ? var.availability_zones : [0]) :
      "${group.name}${(zone == 0 ? "" : "-${zone}")}" => {
        vm_size  = local.instance_types[group.instance_size]
        max_pods = (((local.instance_eni_count[group.instance_size] - 1) * (local.ips_per_eni[group.instance_size] - 1)) + 2)
        taints   = join(",", distinct(compact([lookup(local.worker_group_taints, group.tier, ""), lookup(local.worker_group_taints, group.lifecycle, "")])))
        labels = {
          "lnrs.io/subnet"    = (contains(local.public_tiers, group.tier) ? local.subnet_groups.public[0] : local.subnet_groups.private[0])
          "lnrs.io/tier"      = group.tier
          "lnrs.io/lifecycle" = group.lifecycle
          "lnrs.io/size"      = group.instance_size
        }
        tags                  = merge(local.worker_groups_tags, group.tags)
        node_count            = null
        min_count             = group.min_instances
        max_count             = group.max_instances
        availability_zones    = (zone != 0 ? [zone] : var.availability_zones)
        subnet                = (contains(local.public_tiers, group.tier) ? "public" : "private")
        enable_node_public_ip = (group.subnet_group == "public" ? true : false)
      }
    }
  })...)

  #  worker_groups = [for group in concat(flatten([for group in var.worker_groups :
  #    [for index, subnet in local.subnet_groups[group.subnet_group] : merge(group, {
  #      name    = "${group.name}-${index}-"
  #      subnets = [subnet]
  #    })] if ! group.multi_zone
  #    ]),
  #   [for group in var.worker_groups : merge(group, {
  #      name    = "${group.name}-"
  #      subnets = local.subnet_groups[group.subnet_group]
  #      taints  = join(",", distinct(compact([lookup(local.worker_group_taints, group.tier, ""), lookup(local.worker_group_taints, group.lifecycle, "")])))
  #      }) if group.multi_zone
  #      ]) : merge({ tags                        = [] }, {
  #      name                                     = group.name
  #      subnets                                  = group.subnets
  #      public_ip                                = group.subnet_group == "public" ? true : false
  #      instance_type                            = local.instance_types[group.instance_size]
  #      override_instance_types                  = group.lifecycle == "normal" ? [] : local.spot_instance_types[group.instance_size]
  #      kubelet_extra_args                       = trimspace("--max-pods ${((local.instance_eni_count[group.instance_size] - 1) * (local.ips_per_eni[group.instance_size] - 1)) + 2}" : ""} ${length(group.taints) > 0 ? "--register-with-taints=${group.taints}" : ""}")
  #      max_pods                                 = "foo"
  #      node_labels                              = merge(local.worker_group_labels, {"lnrs.io/subnet" = "something" })
  #      asg_min_size                             = group.min_instances
  #      asg_max_size                             = group.max_instances
  #      asg_desired_capacity                     = null
  #      tags = concat(group.tags, local.worker_groups_tags, {
  #          "lnrs.io/tier" = group.tier
  #        }
  #      )
  #  })] 
}