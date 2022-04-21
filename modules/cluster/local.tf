data "azurerm_client_config" "current" {
}

locals {
  log_categories = ["kube-apiserver", "kube-audit", "kube-audit-admin", "kube-controller-manager", "kube-scheduler", "cluster-autoscaler", "cloud-controller-manager", "guard", "csi-azuredisk-controller", "csi-azurefile-controller", "csi-snapshot-controller"]

  logging_config = merge({
    workspace = {
      name                       = "control-plane-workspace"
      log_analytics_workspace_id = azurerm_log_analytics_workspace.default.id
      storage_account_id         = null
      logs                       = local.log_categories
      metrics                    = []
      retention_enabled          = false
      retention_days             = 0
    }
    }, length(var.logging_storage_account_id) > 0 ? {
    storage_account = {
      name                       = "control-plane-storage-account"
      log_analytics_workspace_id = null
      storage_account_id         = var.logging_storage_account_id
      logs                       = local.log_categories
      metrics                    = []
      retention_enabled          = true
      retention_days             = 7
    }
  } : {})
}
