locals {
  az_count = length(var.availability_zones)

  node_group_overrides = merge({
    }, var.experimental.arm64 ? {} : {
    node_arch = "amd64"
    }, var.experimental.node_group_os_config ? {} : {
    os_config = { sysctl = {} }
    }, var.experimental.azure_cni_max_pods ? {} : {
    max_pods = -1
  })

  system_node_groups_input = {
    system = {
      system              = true
      node_arch           = "amd64"
      node_os             = "ubuntu"
      node_type           = "gp"
      node_type_variant   = "default"
      node_type_version   = "v1"
      node_size           = "xlarge"
      single_group        = false
      min_capacity        = local.az_count
      max_capacity        = local.az_count * 4
      os_config           = { sysctl = {} }
      ultra_ssd           = false
      placement_group_key = null
      max_pods            = -1
      max_surge           = "10%"
      labels = {
        "lnrs.io/tier" = "system"
      }
      taints = [{
        key    = "CriticalAddonsOnly"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
      tags = {}
    }
  }

  node_groups = merge({ for k, v in var.node_groups : k => merge(var.node_groups, v, { system = false }, local.node_group_overrides) }, local.system_node_groups_input)

  placement_group_keys  = distinct(compact([for k, v in local.node_groups : v.placement_group_key if !v.single_group]))
  placement_group_names = flatten([for k in local.placement_group_keys : [for z in var.availability_zones : "${k}${z}"]])

  node_groups_expanded_0 = merge(concat([for k, v in local.node_groups : { for z in var.availability_zones : format("%s%s", k, z) => merge(v, {
    availability_zones = [z]
    az                 = z
    min_capacity       = floor(v.min_capacity / local.az_count)
    max_capacity       = floor(v.max_capacity / local.az_count)
    }) } if !v.single_group],
    [for k, v in local.node_groups : { format("%s0", k) = merge(v, {
      availability_zones = var.availability_zones
      az                 = 0
  }) } if v.single_group])...)

  node_groups_expanded_1 = { for k, v in local.node_groups_expanded_0 : k => merge(v, {
    proximity_placement_group_id = v.single_group || v.placement_group_key == null || v.placement_group_key == "" ? null : azurerm_proximity_placement_group.default["${v.placement_group_key}${v.az}"].id
  }) }

  system_node_groups = { for k, v in local.node_groups_expanded_1 : k => v if v.system }
  user_node_groups   = { for k, v in local.node_groups_expanded_1 : k => v if !v.system }

  ingress_node_group = anytrue([for group in var.node_groups : try(group.labels["lnrs.io/tier"] == "ingress", false) && (length(group.taints) == 0 || (length(group.taints) == 1 && try(group.taints[0].key == "ingress", false)))])
}
