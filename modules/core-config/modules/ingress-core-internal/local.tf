locals {
  namespace = "ingress-core-internal"

  chart_version = "3.33.0"

  chart_values = {

    ##################
    ### controller ###

    controller = {
      podAnnotations = {
        "fluentbit.io/parser"  = "k8s-nginx-ingress"
      }

      ingressClass = "core-internal"

      priorityClassName = "lnrs-platform-critical"

      service = {
        annotations = {
          "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
        }

        type = "LoadBalancer"
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
        "proxy-real-ip-cidr"           = join(",", var.lb_cidrs)
      }

      proxySetHeaders = {
        "Referrer-Policy" = "strict-origin-when-cross-origin"
      }

      extraArgs = {
        "enable-ssl-chain-completion" = "false"
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
        minReplicas                       = var.min_replicas
        maxReplicas                       = var.max_replicas
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
          cpu    = "200m"
          memory = "256Mi"
        }

        limits = {
          cpu    = "200m"
          memory = "256Mi"
        }
      }
    }


    #####################
    ### defaultBacked ###

    defaultBackend = {
      enabled      = true
      replicaCount = 3
      minAvailable = 1

      priorityClassName = "lnrs-cluster-default"

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
