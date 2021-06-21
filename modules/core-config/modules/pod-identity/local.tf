locals {
  node_resource_group_id   = "/subscriptions/${var.azure_subscription_id}/resourceGroups/${var.aks_node_resource_group_name}"
  parent_resource_group_id = "/subscriptions/${var.azure_subscription_id}/resourceGroups/${var.resource_group_name}"

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