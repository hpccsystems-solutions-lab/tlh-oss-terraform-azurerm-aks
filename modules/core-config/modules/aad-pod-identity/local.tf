locals {
  chart_version = "4.1.18"

  chart_values = {
    rbac = {
      enabled              = true
      allowAccessToSecrets = false
    }

    forceNamespaced = true

    installCRDs = false

    mic = {
      priorityClassName = "system-cluster-critical"

      nodeSelector = {
        "kubernetes.io/os" = "linux"
        "lnrs.io/tier"     = "system"
      }

      tolerations = [
        {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
        },
        {
          key      = "system"
          operator = "Exists"
        }
      ]

      podLabels = var.labels

      podDisruptionBudget = {
        minAvailable = 1
      }

      resources = {
        requests = {
          cpu    = "20m"
          memory = "128Mi"
        }

        limits = {
          cpu    = "1000m"
          memory = "128Mi"
        }
      }

      logVerbosity  = local.klog_level_lookup[var.log_level]
      loggingFormat = "json"
    }

    nmi = {
      priorityClassName = "system-node-critical"

      allowNetworkPluginKubenet = (var.cni == "kubenet" ? true : false)

      tolerations = [{
        operator = "Exists"
      }]

      podLabels = var.labels

      resources = {
        requests = {
          cpu    = "20m"
          memory = "64Mi"
        }

        limits = {
          cpu    = "1000m"
          memory = "64Mi"
        }
      }

      logVerbosity  = local.klog_level_lookup[var.log_level]
      loggingFormat = "json"
    }
  }

  klog_level_lookup = {
    "ERROR" = 1
    "WARN"  = 2
    "INFO"  = 3
    "DEBUG" = 4
  }
}
