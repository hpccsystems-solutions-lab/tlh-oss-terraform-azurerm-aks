locals {
  letsencrypt_endpoint = {
    staging    = "https://acme-staging-v02.api.letsencrypt.org/directory"
    production = "https://acme-v02.api.letsencrypt.org/directory"
  }

  chart_values = {
    installCRDs = false

    global = {
      priorityClassName = "lnrs-platform-critical"
    }

    resources = {
      limits = {
        cpu = "1000m"
        memory = "500Mi"
      }
      requests = {
        cpu = "200m"
        memory = "256Mi"
      }
    }

    cainjector = {
      replicaCount = 1
      extraArgs = [
        "--leader-elect=false",
      ]
      nodeSelector = {
        "kubernetes.azure.com/mode" = "system"
      }
      replicaCount = 1
      tolerations = [
        {
          effect = "NoSchedule"
          key = "CriticalAddonsOnly"
          operator = "Exists"
        },
      ]
    }

    extraArgs = [
      "--dns01-recursive-nameservers-only",
      "--dns01-recursive-nameservers=8.8.8.8:53,1.1.1.1:53",
    ]

    nodeSelector = {
      "kubernetes.azure.com/mode" = "system"
    }

    podLabels = {
      aadpodidbinding = module.identity.name
    }

    resources = {
      limits = {
        cpu = "500m"
        memory = "256Mi"
      }
      requests = {
        cpu = "100m"
        memory = "128Mi"
      }
    }

    securityContext = {
      fsGroup = 65534
    }

    tolerations = [
      {
        effect = "NoSchedule"
        key = "CriticalAddonsOnly"
        operator = "Exists"
      },
    ]

    webhook = {
      hostNetwork = true
      nodeSelector = {
        "kubernetes.azure.com/mode" = "system"
      }
      replicaCount = 2
      resources = {
        limits = {
          cpu = "200m"
          memory = "128Mi"
        }
        requests = {
          cpu = "50m"
          memory = "64Mi"
        }
      }
      securePort = 10251
      tolerations = [
        {
          effect = "NoSchedule"
          key = "CriticalAddonsOnly"
          operator = "Exists"
        },
      ]
    }
  }
}