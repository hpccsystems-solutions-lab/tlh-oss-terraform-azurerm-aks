data "azurerm_client_config" "current" {
}

data "azurerm_public_ip" "outbound" {
  count = var.nat_gateway_id == null ? var.managed_outbound_ip_count : 0

  name                = reverse(split("/", tolist(azurerm_kubernetes_cluster.default.network_profile[0].load_balancer_profile[0].effective_outbound_ips)[count.index]))[0]
  resource_group_name = azurerm_kubernetes_cluster.default.node_resource_group
}

data "azurerm_monitor_diagnostic_categories" "default" {
  resource_id = azurerm_kubernetes_cluster.default.id
}

locals {
  sku_tier_lookup = {
    free     = "Free"
    standard = "Standard"
  }

  log_category_types_audit     = ["kube-audit", "kube-audit-admin"]
  log_category_types_audit_fix = ["kube-audit-admin"]

  available_log_category_types = tolist(data.azurerm_monitor_diagnostic_categories.default.log_category_types)

  log_category_types_lookup = {
    "all" = tolist(setintersection(["kube-apiserver", "kube-audit", "kube-controller-manager", "kube-scheduler", "cluster-autoscaler", "cloud-controller-manager", "guard", "csi-azuredisk-controller", "csi-azurefile-controller", "csi-snapshot-controller"], local.available_log_category_types))

    "audit-write-only" = tolist(setintersection(["kube-apiserver", "kube-audit-admin", "kube-controller-manager", "kube-scheduler", "cluster-autoscaler", "cloud-controller-manager", "guard", "csi-azuredisk-controller", "csi-azurefile-controller", "csi-snapshot-controller"], local.available_log_category_types))

    "minimal" = tolist(setintersection(["kube-apiserver", "kube-audit-admin", "kube-controller-manager", "cloud-controller-manager", "guard"], local.available_log_category_types))

    "empty" = []
  }

  log_analytics_log_category_types_input = distinct(concat(local.log_category_types_lookup[var.logging.control_plane.log_analytics.profile], var.logging.control_plane.log_analytics.additional_log_category_types))
  log_analytics_log_category_types       = length(setintersection(local.log_analytics_log_category_types_input, local.log_category_types_audit)) > 1 ? setsubtract(local.log_analytics_log_category_types_input, local.log_category_types_audit_fix) : local.log_analytics_log_category_types_input

  storage_account_log_category_types_input = distinct(concat(local.log_category_types_lookup[var.logging.control_plane.storage_account.profile], var.logging.control_plane.storage_account.additional_log_category_types))
  storage_account_log_category_types       = length(setintersection(local.storage_account_log_category_types_input, local.log_category_types_audit)) > 1 ? setsubtract(local.storage_account_log_category_types_input, local.log_category_types_audit_fix) : local.storage_account_log_category_types_input

  maintenance_window_location_offsets = {
    westeurope = 0
    uksouth    = 0
    eastus     = 5
    eastus2    = 5
    centralus  = 6
    westus     = 8
  }

  maintenance_window_offset = var.maintenance_window_offset != null ? var.maintenance_window_offset : lookup(local.maintenance_window_location_offsets, var.location, 0)

  maintenance_window_allowed_days = length(var.maintenance_window_allowed_days) == 0 ? ["Tuesday", "Wednesday", "Thursday"] : var.maintenance_window_allowed_days

  maintenance_window_allowed_hours = length(var.maintenance_window_allowed_hours) == 0 ? [10, 11, 12, 13, 14, 15] : var.maintenance_window_allowed_hours

  maintenance_window_not_allowed = length(var.maintenance_window_not_allowed) == 0 ? [] : var.maintenance_window_not_allowed

  maintenance_window = {
    allowed = [for d in local.maintenance_window_allowed_days : {
      day   = d
      hours = [for h in local.maintenance_window_allowed_hours : h + local.maintenance_window_offset]
    }]
    not_allowed = [for x in local.maintenance_window_not_allowed : {
      start = timeadd(x.start, format("%vh", local.maintenance_window_offset))
      end   = timeadd(x.end, format("%vh", local.maintenance_window_offset))
    }]
  }
}
