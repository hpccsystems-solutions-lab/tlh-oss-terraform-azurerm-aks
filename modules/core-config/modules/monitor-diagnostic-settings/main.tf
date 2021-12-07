resource "kubectl_manifest" "resources" {
  for_each = local.resource_files

  yaml_body = file(each.value)

  server_side_apply = true
}

resource "azurerm_monitor_diagnostic_setting" "control-plane-law" {
  name               = "control-plane-law"
  target_resource_id = var.cluster_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.control-plane-law.id
  log {
    category = "kube-apiserver"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "kube-audit"
    enabled  = false
    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "kube-audit-admin"
    enabled  = false
    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "kube-controller-manager"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "kube-scheduler"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "cluster-autoscaler"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "guard"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "cloud-controller-manager"
    enabled  = false
    retention_policy {
      days    = 0
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = false
    retention_policy {
      days    = 0
      enabled = false
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "control-plane-stoacc" {
  count = length(var.storage_account_id) > 0 ? 1 : 0

  name               = "control-plane-stoacc"
  target_resource_id = var.cluster_id
  storage_account_id = var.storage_account_id
  log {
    category = "kube-apiserver"
    enabled  = true
    retention_policy {
      days    = 7
      enabled = true
    }
  }
  log {
    category = "kube-audit"
    enabled  = true
    retention_policy {
      days    = 7
      enabled = false
    }
  }
  log {
    category = "kube-audit-admin"
    enabled  = true
    retention_policy {
      days    = 7
      enabled = true
    }
  }
  log {
    category = "kube-controller-manager"
    enabled  = true
    retention_policy {
      days    = 7
      enabled = true
    }
  }
  log {
    category = "kube-scheduler"
    enabled  = true
    retention_policy {
      days    = 7
      enabled = true
    }
  }
  log {
    category = "cluster-autoscaler"
    enabled  = true
    retention_policy {
      days    = 7
      enabled = true
    }
  }
  log {
    category = "guard"
    enabled  = true
    retention_policy {
      days    = 7
      enabled = true
    }
  }

  log {
    category = "cloud-controller-manager"
    enabled  = false
    retention_policy {
      days    = 7
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = false
    retention_policy {
      days    = 7
      enabled = false
    }
  }
}