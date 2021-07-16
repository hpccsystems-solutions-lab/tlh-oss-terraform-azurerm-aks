locals {

  crd_files      = { for x in fileset(path.module, "crds/*.yaml") : basename(x) => "${path.module}/${x}" }
  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }

  letsencrypt_endpoint = {
    staging    = "https://acme-staging-v02.api.letsencrypt.org/directory"
    production = "https://acme-v02.api.letsencrypt.org/directory"
  }

  namespace = "cert-manager"

  chart_version = "1.4.0"

  chart_values = {
    installCRDs = false

    global = {
      priorityClassName = "system-cluster-critical"
    }

    securityContext = {
      fsGroup = 65534
    }

    podLabels = {
      aadpodidbinding = module.identity.name
    }

    extraArgs = [
      "--dns01-recursive-nameservers-only",
      "--dns01-recursive-nameservers=8.8.8.8:53,1.1.1.1:53",
    ]

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

    ###########################################
    ### Caininjector ##########################

    cainjector = {

      replicaCount = 1

      extraArgs = [
        "--leader-elect=false",
      ]

      nodeSelector = {
        "kubernetes.io/os"          = "linux"
        "kubernetes.azure.com/mode" = "system"
      }

      replicaCount = 1

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
    }
    ### End of Caininjector ###################
    ###########################################

    ###########################################
    ### Webhook ###############################

    webhook = {
      securePort  = 10251
      hostNetwork = true

      nodeSelector = {
        "kubernetes.io/os"          = "linux"
        "kubernetes.azure.com/mode" = "system"
      }

      replicaCount = 2

      tolerations = [{
        key      = "CriticalAddonsOnly"
        operator = "Exists"
        effect   = "NoSchedule"
      }]

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
    ### End of Webhook ########################
    ###########################################
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
