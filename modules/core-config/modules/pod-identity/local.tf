locals {
  helm_chart_version = "4.1.0"

  chart_values = {
    forceNamespaced = true
    installCRDs = false
    mic = {
      nodeSelector = {
        "kubernetes.azure.com/mode" = "system"
      }
      tolerations = [
        {
          effect = "NoSchedule"
          key = "CriticalAddonsOnly"
          operator = "Exists"
        },
      ]
    }
    nmi = {
      allowNetworkPluginKubenet = (var.network_plugin == "kubenet" ? true : false)
      tolerations = [
        {
          operator = "Exists"
        },
      ]
    }
    rbac = {
      allowAccessToSecrets = false
    }
  }
}