resource "random_string" "workspace_suffix" {
  count = var.logging.control_plane.log_analytics.enabled && !var.logging.control_plane.log_analytics.external_workspace ? 1 : 0

  length  = 5
  special = false
  lower   = true
  upper   = false
}

resource "azurerm_log_analytics_workspace" "default" {
  count = var.logging.control_plane.log_analytics.enabled && !var.logging.control_plane.log_analytics.external_workspace ? 1 : 0

  location            = var.location
  resource_group_name = var.resource_group_name

  name              = "${regex("aks-\\d+", var.cluster_name)}-control-plane-logs-${random_string.workspace_suffix[0].result}"
  retention_in_days = 30
  tags              = merge(var.tags, { description = "control-plane-logs" })
}

resource "azurerm_monitor_diagnostic_setting" "workspace" {
  count = var.logging.control_plane.log_analytics.enabled ? 1 : 0

  name               = "control-plane-log-analytics"
  target_resource_id = azurerm_kubernetes_cluster.default.id

  log_analytics_workspace_id = var.logging.control_plane.log_analytics.external_workspace ? var.logging.control_plane.log_analytics.workspace_id : azurerm_log_analytics_workspace.default[0].id

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
    ignore_changes = [log_analytics_destination_type]
  }
}

resource "azurerm_monitor_diagnostic_setting" "storage_account" {
  count = var.logging.control_plane.storage_account.enabled ? 1 : 0

  name               = "control-plane-storage-account"
  target_resource_id = azurerm_kubernetes_cluster.default.id

  storage_account_id = var.logging.storage_account_config.id == null ? var.logging.control_plane.storage_account.id : var.logging.storage_account_config.id

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
