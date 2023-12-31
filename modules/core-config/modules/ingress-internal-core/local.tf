locals {
  name = "core-internal"

  chart_version = "4.8.1"

  chart_values = {
    commonLabels = var.labels

    controller = {
      service = {
        annotations = merge({
          "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
          }, var.lb_subnet_name != null ? {
          "service.beta.kubernetes.io/azure-load-balancer-internal-subnet" = var.lb_subnet_name
        } : {})

        type                  = "LoadBalancer"
        externalTrafficPolicy = "Local"

        loadBalancerSourceRanges = var.lb_source_cidrs

        enableHttps = true
        enableHttp  = true
      }

      metrics = {
        enabled = true

        serviceMonitor = {
          enabled = true

          additionalLabels = {
            "lnrs.io/monitoring-platform" = "true"
          }
        }
      }

      nodeSelector = merge({
        "kubernetes.io/os" = "linux"
        }, var.ingress_node_group ? {
        "lnrs.io/tier" = "ingress"
        } : {
        "lnrs.io/tier" = "system"
      })

      tolerations = var.ingress_node_group ? [
        {
          key      = "ingress"
          operator = "Exists"
        }
        ] : [
        {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
        },
        {
          key      = "system"
          operator = "Exists"
        }
      ]

      labels = var.labels

      affinity = {
        podAntiAffinity = {
          preferredDuringSchedulingIgnoredDuringExecution = [
            {
              podAffinityTerm = {
                labelSelector = {
                  matchLabels = {
                    "app.kubernetes.io/name"      = "ingress-nginx"
                    "app.kubernetes.io/instance"  = local.name
                    "app.kubernetes.io/component" = "controller"
                  }
                }

                topologyKey = "kubernetes.io/hostname"
              }

              weight = 100
            },
            {
              podAffinityTerm = {
                labelSelector = {
                  matchLabels = {
                    "app.kubernetes.io/name"      = "ingress-nginx"
                    "app.kubernetes.io/instance"  = local.name
                    "app.kubernetes.io/component" = "controller"
                  }
                }
                topologyKey = "topology.kubernetes.io/zone"
              }
              weight = 50
            }
          ]
        }
      }

      priorityClassName = ""

      resources = {
        requests = {
          cpu    = "50m"
          memory = "256Mi"
        }

        limits = {
          cpu    = "1000m"
          memory = "256Mi"
        }
      }

      extraArgs = {
        "v" = local.klog_level_lookup[var.log_level]
      }

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
          maxSurge       = "100%"
          maxUnavailable = "34%"
        }
      }

      minAvailable = "66%"

      ingressClassResource = {
        enabled         = true
        name            = local.name
        default         = false
        controllerValue = "k8s.io/nginx-${local.name}"
        parameters      = {}
      }

      ingressClass = ""

      config = {
        "error-log-level"              = local.log_level_lookup[var.log_level]
        "server-name-hash-bucket-size" = "256"
        "server-tokens"                = "false"
        "use-proxy-protocol"           = "false"
        "use-forwarded-headers"        = "true"
        "worker-shutdown-timeout"      = "240"
      }

      proxySetHeaders = {
        "Referrer-Policy" = "strict-origin-when-cross-origin"
      }

      extraArgs = {
        "enable-ssl-chain-completion" = "false"
        "default-ssl-certificate"     = "${var.namespace}/internal-ingress-wildcard-cert"
      }

      allowSnippetAnnotations = "false"

      admissionWebhooks = {
        port = 10250

        patch = {
          priorityClassName = ""

          nodeSelector = merge({
            "kubernetes.io/os" = "linux"
            }, var.ingress_node_group ? {
            "lnrs.io/tier" = "ingress"
            } : {
            "lnrs.io/tier" = "system"
          })

          tolerations = var.ingress_node_group ? [
            {
              key      = "ingress"
              operator = "Exists"
            }
            ] : [
            {
              key      = "CriticalAddonsOnly"
              operator = "Exists"
            },
            {
              key      = "system"
              operator = "Exists"
            }
          ]
        }
      }
    }

    defaultBackend = {
      enabled      = true
      replicaCount = 3
      minAvailable = 1

      nodeSelector = {
        "kubernetes.io/os"   = "linux"
        "kubernetes.io/arch" = "amd64"
        "lnrs.io/tier"       = "system"
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

      labels = var.labels

      priorityClassName = ""

      resources = {
        requests = {
          cpu    = "100m"
          memory = "32Mi"
        }

        limits = {
          cpu    = "1000m"
          memory = "32Mi"
        }
      }
    }
  }

  certificate = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"

    metadata = {
      name      = "internal-ingress-wildcard"
      namespace = var.namespace
      labels    = var.labels
    }

    spec = {
      dnsNames = [
        var.domain,
        "*.${var.domain}"
      ]

      issuerRef = {
        group = "cert-manager.io"
        kind  = var.certificate_issuer_kind
        name  = var.certificate_issuer_name
      }

      secretName = "internal-ingress-wildcard-cert"
    }
  }

  log_level_lookup = {
    "ERROR" = "error"
    "WARN"  = "warn"
    "INFO"  = "info"
    "DEBUG" = "debug"
  }

  klog_level_lookup = {
    "ERROR" = 1
    "WARN"  = 2
    "INFO"  = 3
    "DEBUG" = 4
  }

  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
}
