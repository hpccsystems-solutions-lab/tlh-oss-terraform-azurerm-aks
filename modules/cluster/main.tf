resource "azurerm_user_assigned_identity" "default" {
  name                = "${var.cluster_name}-control-plane"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "network_contributor_network" {
  principal_id         = azurerm_user_assigned_identity.default.principal_id
  role_definition_name = "Network Contributor"
  scope                = var.subnet_id
}

resource "azurerm_role_assignment" "network_contributor_route_table" {
  count = var.cni == "KUBENET" ? 1 : 0

  principal_id         = azurerm_user_assigned_identity.default.principal_id
  role_definition_name = "Network Contributor"
  scope                = var.route_table_id
}

resource "azurerm_role_assignment" "network_contributor_nat_gateway" {
  count = var.nat_gateway_id != null ? 1 : 0

  principal_id         = azurerm_user_assigned_identity.default.principal_id
  role_definition_name = "Network Contributor"
  scope                = var.nat_gateway_id
}

resource "terraform_data" "maintenance_control_plane_start_date" {
  input = "${formatdate("YYYY-MM-DD", timecmp("${formatdate("YYYY-MM-DD", timestamp())}T${var.maintenance.control_plane.start_time}:00${local.maintenance_utc_offset}", timestamp()) == -1 ? timeadd(timestamp(), "24h") : timestamp())}T00:00:00Z"

  triggers_replace = [
    local.maintenance_utc_offset,
    var.maintenance.control_plane
  ]

  lifecycle {
    ignore_changes = [input]
  }
}

resource "terraform_data" "maintenance_nodes_start_date" {
  input = "${formatdate("YYYY-MM-DD", timecmp("${formatdate("YYYY-MM-DD", timestamp())}T${var.maintenance.nodes.start_time}:00${local.maintenance_utc_offset}", timestamp()) == -1 ? timeadd(timestamp(), "24h") : timestamp())}T00:00:00Z"

  triggers_replace = [
    local.maintenance_utc_offset,
    var.maintenance.nodes
  ]

  lifecycle {
    ignore_changes = [input]
  }
}

#tfsec:ignore:azure-container-limit-authorized-ips
#tfsec:ignore:azure-container-logging
resource "azurerm_kubernetes_cluster" "default" {
  name               = var.cluster_name
  kubernetes_version = var.cluster_version
  sku_tier           = local.sku_tier_lookup[var.sku_tier]

  automatic_channel_upgrade = !var.manual_upgrades ? "patch" : null
  node_os_channel_upgrade   = !var.manual_upgrades ? "NodeImage" : "None"

  resource_group_name = var.resource_group_name
  location            = var.location

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.default.id]
  }

  api_server_access_profile {
    authorized_ip_ranges = length(var.cluster_endpoint_access_cidrs) == 0 ? ["0.0.0.0/32"] : var.cluster_endpoint_access_cidrs
  }

  network_profile {
    network_plugin      = local.cni_lookup[var.cni]
    network_plugin_mode = var.cni == "AZURE_OVERLAY" ? "overlay" : null
    network_policy      = "calico"
    service_cidr        = "172.20.0.0/16"
    dns_service_ip      = "172.20.0.10"
    pod_cidr            = var.cni != "AZURE" ? var.podnet_cidr_block : null

    outbound_type = var.nat_gateway_id != null ? "userAssignedNATGateway" : "loadBalancer"

    dynamic "load_balancer_profile" {
      for_each = var.nat_gateway_id == null ? ["default"] : []
      content {
        managed_outbound_ip_count = var.managed_outbound_ip_count
        outbound_ports_allocated  = var.managed_outbound_ports_allocated
        idle_timeout_in_minutes   = var.managed_outbound_idle_timeout / 60
      }
    }
  }

  dns_prefix = var.cluster_name

  local_account_disabled            = false
  role_based_access_control_enabled = true

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    #admin_group_object_ids = var.admin_group_object_ids
  }

  azure_policy_enabled = false

  auto_scaler_profile {
    balance_similar_node_groups   = true
    expander                      = "random"
    skip_nodes_with_system_pods   = false
    skip_nodes_with_local_storage = false
  }

  storage_profile {
    disk_driver_enabled = true
    disk_driver_version = "v1" # TODO: explore experimental support of v2 driver version

    file_driver_enabled         = var.storage.file.enabled
    blob_driver_enabled         = var.storage.blob.enabled
    snapshot_controller_enabled = true # Default is true - We may explore allowing operators to disable this feature in future updates.
  }

  maintenance_window_auto_upgrade {
    utc_offset   = local.maintenance_utc_offset
    frequency    = local.maintainance_frequency_lookup[var.maintenance.control_plane.frequency]
    interval     = local.maintainance_interval_lookup[var.maintenance.control_plane.frequency]
    day_of_month = var.maintenance.control_plane.frequency == "MONTHLY" ? var.maintenance.control_plane.day_of_month : null
    day_of_week  = var.maintenance.control_plane.frequency == "WEEKLY" || var.maintenance.control_plane.frequency == "FORTNIGHTLY" ? local.maintainance_day_of_week_lookup[var.maintenance.control_plane.day_of_week] : null
    start_date   = terraform_data.maintenance_control_plane_start_date.output
    start_time   = var.maintenance.control_plane.start_time
    duration     = var.maintenance.control_plane.duration

    dynamic "not_allowed" {
      for_each = var.maintenance.not_allowed

      content {
        start = not_allowed.value.start
        end   = not_allowed.value.end
      }
    }
  }

  maintenance_window_node_os {
    utc_offset   = local.maintenance_utc_offset
    frequency    = local.maintainance_frequency_lookup[var.maintenance.nodes.frequency]
    interval     = local.maintainance_interval_lookup[var.maintenance.nodes.frequency]
    day_of_month = var.maintenance.nodes.frequency == "MONTHLY" ? var.maintenance.nodes.day_of_month : null
    day_of_week  = var.maintenance.nodes.frequency == "WEEKLY" || var.maintenance.nodes.frequency == "FORTNIGHTLY" ? local.maintainance_day_of_week_lookup[var.maintenance.nodes.day_of_week] : null
    start_date   = terraform_data.maintenance_nodes_start_date.output
    start_time   = var.maintenance.nodes.start_time
    duration     = var.maintenance.nodes.duration

    dynamic "not_allowed" {
      for_each = var.maintenance.not_allowed

      content {
        start = not_allowed.value.start
        end   = not_allowed.value.end
      }
    }
  }

  node_resource_group = "ng_${var.cluster_name}"

  default_node_pool {
    name = var.bootstrap_name

    type           = "VirtualMachineScaleSets"
    vnet_subnet_id = var.subnet_id
    zones          = [1, 2, 3]

    node_count                   = 1
    enable_auto_scaling          = false
    only_critical_addons_enabled = true

    vm_size                = var.bootstrap_vm_size
    os_disk_type           = "Managed"
    enable_host_encryption = true
    enable_node_public_ip  = false

    fips_enabled = var.fips

    tags = var.tags
  }

  dynamic "oms_agent" {
    for_each = var.oms_agent ? ["default"] : []
    content {
      log_analytics_workspace_id = var.oms_agent_log_analytics_workspace_id
    }
  }

  dynamic "windows_profile" {
    for_each = var.windows_support ? ["default"] : []
    content {
      admin_username = random_password.windows_admin_username[0].result
      admin_password = random_password.windows_admin_password[0].result
    }
  }

  tags = var.tags

  timeouts {
    create = format("%vm", var.timeouts.cluster_create / 60)
    read   = format("%vm", var.timeouts.cluster_read / 60)
    update = format("%vm", var.timeouts.cluster_update / 60)
    delete = format("%vm", var.timeouts.cluster_delete / 60)
  }

  lifecycle {
    ignore_changes = [
      default_node_pool,
      tags["lnrs.io_terraform-module-version"]
    ]
  }

  depends_on = [
    azurerm_role_assignment.network_contributor_network,
    azurerm_role_assignment.network_contributor_route_table
  ]
}

resource "time_sleep" "modify" {
  create_duration = "30s"

  triggers = {
    cluster_version = var.cluster_version
  }

  depends_on = [
    azurerm_kubernetes_cluster.default
  ]
}

data "azurerm_kubernetes_cluster" "default" {
  name                = var.cluster_name
  resource_group_name = var.resource_group_name

  depends_on = [
    azurerm_kubernetes_cluster.default,
    time_sleep.modify
  ]
}

data "azurerm_kubernetes_service_versions" "default" {
  location        = var.location
  version_prefix  = var.cluster_version
  include_preview = false
}
