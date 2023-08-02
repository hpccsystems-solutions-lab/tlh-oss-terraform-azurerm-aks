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

      retention_policy {
        enabled = var.logging.control_plane.log_analytics.retention_enabled
        days    = var.logging.control_plane.log_analytics.retention_enabled ? var.logging.control_plane.log_analytics.retention_days : 0
      }
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

  storage_account_id = coalesce(var.logging.control_plane.storage_account.id, var.logging.storage_account_config.id)

  dynamic "enabled_log" {
    for_each = local.storage_account_log_category_types

    content {
      category = enabled_log.value

      retention_policy {
        enabled = var.logging.control_plane.storage_account.retention_enabled
        days    = var.logging.control_plane.storage_account.retention_enabled ? var.logging.control_plane.storage_account.retention_days : 0
      }
    }
  }
}
