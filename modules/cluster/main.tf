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

#tfsec:ignore:azure-container-limit-authorized-ips
#tfsec:ignore:azure-container-logging
resource "azurerm_kubernetes_cluster" "default" {
  name                      = var.cluster_name
  kubernetes_version        = var.patch_upgrade ? var.cluster_version : var.cluster_version_full
  automatic_channel_upgrade = var.patch_upgrade ? "patch" : "node-image"
  sku_tier                  = local.sku_tier_lookup[var.sku_tier]

  resource_group_name = var.resource_group_name
  location            = var.location

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.default.id]
  }

  public_network_access_enabled = var.cluster_endpoint_public_access

  api_server_access_profile {
    authorized_ip_ranges = length(var.cluster_endpoint_access_cidrs) == 0 ? ["0.0.0.0/32"] : var.cluster_endpoint_access_cidrs
  }

  network_profile {
    network_plugin = var.cni
    network_policy = "calico"
    service_cidr   = "172.20.0.0/16"
    dns_service_ip = "172.20.0.10"
    pod_cidr       = var.cni == "kubenet" ? var.podnet_cidr_block : null

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

  local_account_disabled            = true
  role_based_access_control_enabled = true

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  azure_policy_enabled = false

  auto_scaler_profile {
    balance_similar_node_groups   = true
    expander                      = "random"
    skip_nodes_with_system_pods   = false
    skip_nodes_with_local_storage = false
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

  maintenance_window {
    dynamic "allowed" {
      for_each = local.maintenance_window.allowed
      content {
        day   = allowed.value.day
        hours = allowed.value.hours
      }
    }
    dynamic "not_allowed" {
      for_each = local.maintenance_window.not_allowed
      content {
        end   = not_allowed.value.end
        start = not_allowed.value.start
      }
    }
  }

  storage_profile {
    disk_driver_enabled = true
    disk_driver_version = "v1" # TODO: explore experimental support of v2 driver version

    file_driver_enabled         = var.storage.file.enabled
    blob_driver_enabled         = var.storage.blob.enabled
    snapshot_controller_enabled = true # Default is true - We may explore allowing operators to disable this feature in future updates.
  }

  node_resource_group = "mc_${var.cluster_name}"

  default_node_pool {
    name = var.bootstrap_name

    type           = "VirtualMachineScaleSets"
    vnet_subnet_id = var.subnet_id
    zones          = [1, 2, 3]

    orchestrator_version = var.patch_upgrade ? var.cluster_version : var.cluster_version_full

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
