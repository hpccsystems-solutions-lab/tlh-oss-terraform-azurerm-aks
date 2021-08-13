locals {

  chart_version = "4.1.2"

  chart_values = {

    rbac = {
      enabled              = true
      allowAccessToSecrets = false
    }

    ## match identities within the pod namespace only
    forceNamespaced = true

    installCRDs = false

    ##########################################
    ## Managed Identity Controller ###########

    mic = {
      priorityClassName = "system-cluster-critical"

      nodeSelector = {
        "kubernetes.io/os"          = "linux"
        "kubernetes.azure.com/mode" = "system"
      }

      tolerations = [{
        key      = "CriticalAddonsOnly"
        operator = "Exists"
        effect   = "NoSchedule"
      }]

      podLabels = {
        "lnrs.io/k8s-platform" = "true"
      }

      podDisruptionBudget = {
        minAvailable = 1
      }
    }
    ## End of Managed Identity Controller ####
    ##########################################

    ##########################################
    ## Node Managed Identity #################

    nmi = {
      priorityClassName = "system-node-critical"

      nodeSelector = {
        "kubernetes.io/os" = "linux"
      }

      allowNetworkPluginKubenet = (var.network_plugin == "kubenet" ? true : false)

      tolerations = [{
        operator = "Exists"
      }]

      podLabels = {
        "lnrs.io/k8s-platform" = "true"
      }
    }
    ## End of Node Managed Identity ##########
    ##########################################
  }

  node_resource_group_id   = "/subscriptions/${var.azure_subscription_id}/resourceGroups/${var.aks_node_resource_group_name}"
  parent_resource_group_id = "/subscriptions/${var.azure_subscription_id}/resourceGroups/${var.resource_group_name}"
}
