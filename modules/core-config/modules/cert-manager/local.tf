locals {

  crd_files      = { for x in fileset(path.module, "crds/*.yaml") : basename(x) => "${path.module}/${x}" }
  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }

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
        }
      ]
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

    prometheus = {
      enabled = true
      servicemonitor = {
        enabled = true
        interval = "60s"
        labels = {
          "lnrs.io/monitoring-platform" = "core-prometheus"
        }
        path = "/metrics"
        prometheusInstance = "Prometheus"
        scrapeTimeout = "30s"
        targetPort = 9402
      }
    }
  }

  zones          = keys(var.dns_zones)
  wildcard_zones = [for zone in local.zones : "*.${zone}"]
  certificates = {
    wildcard = {
      apiVersion = "cert-manager.io/v1"
      kind       = "Certificate"
      metadata = {
        name      = "default-wildcard-cert"
        namespace = "cert-manager"
      }
      spec = {
        commonName = "*.${element(local.zones, 0)}"
        dnsNames   = concat(local.zones, local.wildcard_zones)
        issuerRef = {
          kind = "ClusterIssuer"
          name = "letsencrypt-issuer"
        }
        secretName = "default-wildcard-cert-tls"
      }
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
          email  = var.letsencrypt_email
          server = local.letsencrypt_endpoint[lower(var.letsencrypt_environment)]
          privateKeySecretRef = {
            name = "letsencrypt-issuer-privatekey"
          }
          solvers = [ for zone,rg in var.dns_zones : {
            selector = {
              dnsZones = [ zone ]
            }
            dns01 = {
              azureDNS = {
                subscriptionID = var.azure_subscription_id
                resourceGroupName = rg
                hostedZoneName = zone 
                environment: var.azure_environment
              }
            }
          }]
        }
      }
    }
  })
}
