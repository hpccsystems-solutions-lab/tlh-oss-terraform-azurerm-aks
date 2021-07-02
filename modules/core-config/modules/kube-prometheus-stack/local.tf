locals {
  namespace = "monitoring"

  chart_version = "16.8.0"

  kube_state_metrics_image_versions = {
    "1.20" = "v2.0.0"
    "1.19" = "v2.0.0"
    "1.18" = "v1.9.8"
  }

  chart_values = {
    kubeVersionOverride = "v${var.cluster_version}.0"

    global = {
      rbac = {
        create     = true
        pspEnabled = false
      }
    }

    commonLabels = {
      "lnrs.io/monitoring-platform" = "core-prometheus"
      "lnrs.io/k8s-platform"        = "true"
    }

    prometheus = {
      ingress = {
        enabled          = var.create_ingress
        annotations      = var.ingress_annotations

        ingressClassName = "core-internal"
        pathType         = "Prefix"

        hosts = [ "prometheus-${var.cluster_name}.${var.ingress_domain}" ]
        tls   = [{
          "secretName" = "prometheus-cert"
          "hosts"      = [ "prometheus-${var.cluster_name}.${var.ingress_domain}" ]
        }]
      }

      prometheusSpec = {
        retention = "28d"

        priorityClassName = "lnrs-platform-critical"

        remoteWrite = var.prometheus_remote_write

        podMonitorSelector = {
          matchLabels = {
            "lnrs.io/monitoring-platform" = "core-prometheus"
          }
        }

        ruleSelector = {
          matchLabels = {
            "lnrs.io/monitoring-platform" = "core-prometheus"
          }
        }

        serviceMonitorSelector = {
          matchLabels = {
            "lnrs.io/monitoring-platform" = "core-prometheus"
          }
        }

        nodeSelector = {
          "kubernetes.io/os"  = "linux"
        }

        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = var.prometheus_storage_class_name

              accessModes : [
                "ReadWriteOnce"
              ]

              resources = {
                requests = {
                  storage = "300Gi"
                }
              }
            }
          }
        }

        resources = {
          requests = {
            cpu    = "1000m"
            memory = "2048Mi"
          }

          limits = {
            cpu    = "4000m"
            memory = "8192Mi"
          }
        }
      }
    }

    alertmanager = {
      alertmanagerSpec = {
        priorityClassName = "lnrs-platform-critical"

        retention = "120h"

        nodeSelector = {
          "kubernetes.io/os" = "linux"
        }

        storage = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = var.alertmanager_storage_class_name

              accessModes : [
                "ReadWriteOnce"
              ]

              resources = {
                requests = {
                  storage = "10Gi"
                }
              }
            }
          }
        }

        resources = {
          requests = {
            cpu    = "10m"
            memory = "16Mi"
          }

          limits = {
            cpu    = "100m"
            memory = "64Mi"
          }
        }
      }

      config = {
        global = {
          smtp_require_tls = false
          smtp_smarthost   = var.alertmanager_smtp_host
          smtp_from        = var.alertmanager_smtp_from
        }

        receivers = concat([{ name = "null" }], var.alertmanager_receivers)

        route = {
          group_by = [
            "namespace",
            "severity"
          ]
          group_wait      = "30s"
          group_interval  = "5m"
          repeat_interval = "12h"
          receiver        = "null"

          routes = concat([
            {
              match = {
                alertname = "Watchdog"
              }
              receiver = "null"
          }], var.alertmanager_routes)
        }
      }

      ingress = {
        enabled          = var.create_ingress
        annotations      = var.ingress_annotations

        ingressClassName = "core-internal"
        pathType         = "Prefix"

        hosts = [ "alertmanager-${var.cluster_name}.${var.ingress_domain}" ]
        tls   = [{
          "secretName" = "alertmanager-cert"
          "hosts"      = [ "alertmanager-${var.cluster_name}.${var.ingress_domain}" ]
        }]
      }
    }

    grafana = {
      enabled = true

      admin = {
        existingSecret = local.grafana_auth_secret_name
        userKey        = "admin-user"
        passwordKey    = "admin-password"
      }

      "grafana.ini" = {
        "auth.anonymous" = {
          enabled  = true
          org_role = "Viewer"
        }

        users = {
          viewers_can_edit = true
        }
      }

      plugins = var.grafana_plugins

      additionalDataSources = concat(var.loki_enabled ? [local.grafana_loki_data_source] : [], var.grafana_additional_data_sources)

      priorityClassName = "lnrs-platform-critical"

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

      ingress = {
        enabled          = var.create_ingress
        annotations      = var.ingress_annotations

        ingressClassName = "core-internal"
        pathType         = "Prefix"
        path             = var.cluster_version == "1.18" ? "/*" : "/"

        hosts = [ "grafana-${var.cluster_name}.${var.ingress_domain}" ]
        tls   = [{
          "secretName" = "grafana-cert"
          "hosts"      = [ "grafana-${var.cluster_name}.${var.ingress_domain}" ]
        }]
      }

      resources = {
        requests = {
          cpu    = "10m"
          memory = "128Mi"
        }

        limits = {
          cpu    = "1000m"
          memory = "256Mi"
        }
      }

      sidecar = {
        dashboards = {
          searchNamespace = "ALL"
        }

        resources = {
          requests = {
            cpu    = "10m"
            memory = "64Mi"
          }

          limits = {
            cpu    = "100m"
            memory = "256Mi"
          }
        }
      }
    }

    kubeScheduler = {
      enabled = false
    }

    kubeControllerManager = {
      enabled = false
    }

    kubeEtcd = {
      enabled = false
    }

    kubeProxy = {
      enabled = true

      service = {
        selector = {
          component = "kube-proxy"
        }
      }
    }

    defaultRules = {
      rules = {
        kubernetesSystem    = false
        kubernetesResources = false
        kubernetesStorage   = false
        kubernetesApps      = false
      }
    }

    prometheusOperator = {
      enabled = true

      priorityClassName = "lnrs-platform-critical"

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

      createCustomResource = false
      manageCrds           = false

      resources = {
        requests = {
          cpu    = "50m"
          memory = "256Mi"
        }

        limits = {
          cpu    = "500m"
          memory = "256Mi"
        }
      }

      tlsProxy = {
        resources = {
          requests = {
            cpu    = "5m"
            memory = "8Mi"
          }

          limits = {
            cpu    = "100m"
            memory = "32Mi"
          }
        }
      }
    }

    ## Deploy servicemonitor
    nodeExporter = {
      enabled = true
    }

    prometheus-node-exporter = {
      priorityClassName = "lnrs-platform-critical"

      nodeSelector = {
        "kubernetes.io/os" = "linux"
      }

      tolerations = [
        {
          operator = "Exists"
        }
      ]

      resources = {
        requests = {
          cpu    = "50m"
          memory = "16Mi"
        }

        limits = {
          cpu    = "500m"
          memory = "128Mi"
        }
      }
    }

    ## Deploy servicemonitor
    kubeStateMetrics = {
      enabled = true
    }

    kube-state-metrics = {
      priorityClassName = "lnrs-platform-critical"

      image = {
        tag = local.kube_state_metrics_image_versions[var.cluster_version]
      }

      podSecurityPolicy = {
        enabled = false
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

      ## Avoid duplicate kube-state-metrics servicemonitor
      #prometheus = {
      #  monitor = {
      #    enabled = true
      #    additionalLabels = {
      #      "lnrs.io/monitoring-platform" = "core-prometheus"
      #    }
      #  }
      #}

      resources = {
        requests = {
          cpu    = "10m"
          memory = "64Mi"
        }

        limits = {
          cpu    = "200m"
          memory = "128Mi"
        }
      }
    }
  }

  grafana_auth_secret_name = "grafana-auth"

  grafana_loki_data_source = {
    name   = "Loki"
    type   = "loki"
    url    = "http://loki.logging.svc:3100"
    access = "proxy"
    orgId  = "1"
  }

  crd_files      = { for x in fileset(path.module, "crds/*.yaml") : basename(x) => "${path.module}/${x}" }
  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
}
