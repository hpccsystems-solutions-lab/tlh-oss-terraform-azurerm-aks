locals {

  letsencrypt_endpoint = {
    staging    = "https://acme-staging-v02.api.letsencrypt.org/directory"
    production = "https://acme-v02.api.letsencrypt.org/directory"
  }

  zones = keys(var.dns_zones)

  namespace = "cert-manager"

  chart_version = "1.6.1"

  chart_values = {
    installCRDs = false

    global = {
      priorityClassName = "system-cluster-critical"
    }

    podLabels = {
      aadpodidbinding        = module.identity.name
      "lnrs.io/k8s-platform" = "true"
    }

    securityContext = {
      fsGroup = 65534
    }

    prometheus = {
      enabled = true
      servicemonitor = {
        enabled            = true
        prometheusInstance = "Prometheus"
        targetPort         = 9402
        path               = "/metrics"
        interval           = "60s"
        scrapeTimeout      = "30s"
        labels = {
          "lnrs.io/monitoring-platform" = "core-prometheus"
        }
      }
    }

    nodeSelector = {
      "kubernetes.io/os"          = "linux"
      "kubernetes.azure.com/mode" = "system"
    }

    tolerations = [{
      key      = "CriticalAddonsOnly"
      operator = "Exists"
      effect   = "NoSchedule"
    }]

    resources = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }

      limits = {
        cpu    = "500m"
        memory = "256Mi"
      }
    }

    extraArgs = [
      "--dns01-recursive-nameservers-only",
      "--dns01-recursive-nameservers=8.8.8.8:53,1.1.1.1:53"
    ]

    cainjector = {
      nodeSelector = {
        "kubernetes.io/os"          = "linux"
        "kubernetes.azure.com/mode" = "system"
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

      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }

        limits = {
          cpu    = "500m"
          memory = "256Mi"
        }
      }
    }

    webhook = {
      securePort  = 10251
      hostNetwork = true

      nodeSelector = {
        "kubernetes.io/os"          = "linux"
        "kubernetes.azure.com/mode" = "system"
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

      resources = {
        requests = {
          cpu    = "100m"
          memory = "64Mi"
        }

        limits = {
          cpu    = "200m"
          memory = "128Mi"
        }
      }
    }

    ingressShim = {
      defaultIssuerKind = var.default_issuer_kind
      defaultIssuerName = var.default_issuer_name
    }
  }

  issuers = merge(var.additional_issuers, {
    letsencrypt = {
      apiVersion = "cert-manager.io/v1"
      kind       = "ClusterIssuer"
      metadata = {
        name = "letsencrypt-issuer"
      }
      spec = {
        acme = {
          email  = "systems.engineering@reedbusiness.com"
          server = local.letsencrypt_endpoint[lower(var.letsencrypt_environment)]
          privateKeySecretRef = {
            name = "letsencrypt-issuer-privatekey"
          }
          solvers = [for zone, rg in var.dns_zones : {
            selector = {
              dnsZones = [zone]
            }
            dns01 = {
              azureDNS = {
                subscriptionID    = var.azure_subscription_id
                resourceGroupName = rg
                hostedZoneName    = zone
                environment       = var.azure_environment
              }
            }
          }]
        }
      }
    }
  })

  certificates = {
    ingress_internal_core_wildcard = {
      apiVersion = "cert-manager.io/v1"
      kind       = "Certificate"

      metadata = {
        name      = "internal-ingress-wildcard"
        namespace = local.namespace
      }

      spec = {
        dnsNames = [
          var.ingress_internal_core_domain,
          "*.${var.ingress_internal_core_domain}"
        ]

        issuerRef = {
          group = "cert-manager.io"
          kind  = "ClusterIssuer"
          name  = "letsencrypt-issuer"
        }

        secretName = "internal-ingress-wildcard-cert"
      }
    }
  }

  crd_files      = { for x in fileset(path.module, "crds/*.yaml") : basename(x) => "${path.module}/${x}" }
  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
}
