locals {
  chart_version = "4.1.15"

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
    }
  }

  crd_files = { for x in fileset(path.module, "crds/*.yaml") : basename(x) => "${path.module}/${x}" }
}
