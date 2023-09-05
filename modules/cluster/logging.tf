resource "azurerm_monitor_diagnostic_setting" "workspace" {
  count = var.logging.control_plane.log_analytics.enabled ? 1 : 0

  name               = "control-plane-log-analytics"
  target_resource_id = azurerm_kubernetes_cluster.default.id

  log_analytics_workspace_id = coalesce(var.logging.control_plane.log_analytics.workspace_id, var.logging.log_analytics_workspace_config.id)

  log_analytics_destination_type = "AzureDiagnostics"

  dynamic "enabled_log" {
    for_each = local.log_analytics_log_category_types

    content {
      category = enabled_log.value
    }
  }

  lifecycle {
    ignore_changes = [
      log_analytics_destination_type,
      metric
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "storage_account" {
  count = var.logging.control_plane.storage_account.enabled ? 1 : 0

  name               = "control-plane-storage-account"
  target_resource_id = azurerm_kubernetes_cluster.default.id

  storage_account_id = var.logging.control_plane.storage_account.id != null ? var.logging.control_plane.storage_account.id : var.logging.storage_account_config.id

  dynamic "enabled_log" {
    for_each = local.storage_account_log_category_types

    content {
      category = enabled_log.value
    }
  }

  lifecycle {
    ignore_changes = [metric]
  }
}

resource "azurerm_storage_management_policy" "storage_account" {
  count = var.logging.control_plane.storage_account.retention_enabled ? 1 : 0

  storage_account_id = var.logging.control_plane.storage_account.id != null ? var.logging.control_plane.storage_account.id : var.logging.storage_account_config.id

  rule {
    name    = format("%s-delete-after-%d-days", var.cluster_name, var.logging.control_plane.storage_account.retention_days)
    enabled = true
    filters {
      prefix_match = formatlist("insights-logs-%s/resourceId=%s", local.storage_account_log_category_types, upper(azurerm_kubernetes_cluster.default.id))
      blob_types   = ["appendBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = var.logging.control_plane.storage_account.retention_days
      }
    }
  }
}
