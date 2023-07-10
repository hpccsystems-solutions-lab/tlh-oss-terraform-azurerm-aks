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

  maintenance_utc_offset_lookup = {
    westeurope = "+00:00"
    uksouth    = "+00:00"
    eastus     = "+05:00"
    eastus2    = "+05:00"
    centralus  = "+06:00"
    westus     = "+08:00"
  }

  maintainance_frequency_lookup = {
    "DAILY"       = "Daily"
    "WEEKLY"      = "Weekly"
    "FORTNIGHTLY" = "Weekly"
    "MONTHLY"     = "AbsoluteMonthly"
  }

  maintainance_interval_lookup = {
    "DAILY"       = 1
    "WEEKLY"      = 1
    "FORTNIGHTLY" = 2
    "MONTHLY"     = 1
  }

  maintainance_day_of_week_lookup = {
    "MONDAY"    = "Monday"
    "TUESDAY"   = "Tuesday"
    "WEDNESDAY" = "Wednesday"
    "THURSDAY"  = "Thursday"
    "FRIDAY"    = "Friday"
    "SATURDAY"  = "Saturday"
    "SUNDAY"    = "Sunday"
  }

  maintenance_utc_offset = var.maintenance.utc_offset != null ? var.maintenance.utc_offset : lookup(local.maintenance_utc_offset_lookup, var.location, "+00:00")
}
