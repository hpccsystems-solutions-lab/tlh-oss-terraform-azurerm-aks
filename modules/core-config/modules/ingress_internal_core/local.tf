locals {
  namespace = "ingress-core-internal"

  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }

  chart_version = "4.0.6"

  chart_timeout = 1800

  chart_values = {

    ##################
    ### controller ###

    controller = {
      allowSnippetAnnotations = "false"

      podLabels = {
        "lnrs.io/k8s-platform" = "true"
      }

      podAnnotations = {
        "fluentbit.io/parser" = "k8s-nginx-ingress"
      }

      ingressClassResource = {
        enabled = true
        name = "core-internal"
        default = false
        controllerValue = "k8s.io/nginx-core-internal"
        parameters = {}
      }

      priorityClassName = "system-cluster-critical"

      service = {
        annotations = {
          "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
        }

        type                  = "LoadBalancer"
        externalTrafficPolicy = "Local"

        loadBalancerSourceRanges = var.lb_source_cidrs

        enableHttps = true
        enableHttp  = true
      }

      config = {
        "server-name-hash-bucket-size" = "256"
        "server-tokens"                = "false"
        "use-proxy-protocol"           = "false"
        "use-forwarded-headers"        = "true"
      }

      proxySetHeaders = {
        "Referrer-Policy" = "strict-origin-when-cross-origin"
      }

      extraArgs = {
        "enable-ssl-chain-completion" = "false"
        "default-ssl-certificate"     = "cert-manager/internal-ingress-wildcard-cert"
      }

      nodeSelector = {
        "kubernetes.azure.com/mode" = "system"
      }

      tolerations = [
        {
          key      = "CriticalAddonsOnly"
          operator = "Equal"
          value    = "true"
          effect   = "NoSchedule"
        }
      ]

      autoscaling = {
        enabled                           = true
        minReplicas                       = 3
        maxReplicas                       = 6
        targetCPUUtilizationPercentage    = 80
        targetMemoryUtilizationPercentage = 80
      }

      updateStrategy = {
        type = "RollingUpdate"
        rollingUpdate = {
          maxSurge       = "50%"
          maxUnavailable = "50%"
        }
      }

      affinity = {
        podAntiAffinity = {
          preferredDuringSchedulingIgnoredDuringExecution = [
            {
              podAffinityTerm = {
                labelSelector = {
                  matchExpressions = [
                    {
                      key      = "app.kubernetes.io/name"
                      operator = "In"
                      values = [
                        "ingress-nginx"
                      ]
                    },
                    {
                      key      = "app.kubernetes.io/instance"
                      operator = "In"
                      values = [
                        "ingress-nginx"
                      ]
                    },
                    {
                      key      = "app.kubernetes.io/component"
                      operator = "In"
                      values = [
                        "controller"
                      ]
                    }
                  ]
                }

                topologyKey = "kubernetes.io/hostname"
              }

              weight = 100
            }
          ]
        }
      }

      metrics = {
        enabled = true

        serviceMonitor = {
          enabled = true

          additionalLabels = {
            "lnrs.io/monitoring-platform" = "core-prometheus"
          }
        }
      }

      resources = {
        requests = {
          cpu    = "50m"
          memory = "128Mi"
        }

        limits = {
          cpu    = "200m"
          memory = "256Mi"
        }
      }

      admissionWebhooks = {
        patch = {
          priorityClassName = "system-cluster-critical"

          nodeSelector = {
            "kubernetes.io/os"          = "linux"
            "kubernetes.azure.com/mode" = "system"
          }

          tolerations = [
            {
              key      = "CriticalAddonsOnly"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
          ]
        }
      }
    }


    #####################
    ### defaultBacked ###

    defaultBackend = {
      enabled      = true
      replicaCount = 3
      minAvailable = 1

      podLabels = {
        "lnrs.io/k8s-platform" = "true"
      }

      priorityClassName = ""

      nodeSelector = {
        "kubernetes.azure.com/mode" = "system"
      }

      tolerations = [
        {
          key      = "CriticalAddonsOnly"
          operator = "Equal"
          value    = "true"
          effect   = "NoSchedule"
        }
      ]

      resources = {
        requests = {
          cpu    = "10m"
          memory = "16Mi"
        }

        limits = {
          cpu    = "100m"
          memory = "128Mi"
        }
      }
    }
  }
}
