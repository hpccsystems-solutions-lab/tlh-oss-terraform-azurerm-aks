locals {
  chart_version = "34.1.1"

  chart_values = {
    global = {
      rbac = {
        create     = true
        pspEnabled = false
      }
    }

    commonLabels = merge(var.labels, {
      "lnrs.io/monitoring-platform" = "true"
    })

    prometheusOperator = {
      enabled = true

      priorityClassName = ""

      nodeSelector = {
        "kubernetes.io/os" = "linux"
        "lnrs.io/tier"     = "system"
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
          cpu    = "200m"
          memory = "256Mi"
        }

        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }

      createCustomResource = false
      manageCrds           = false

      prometheusConfigReloader = {
        resources = {
          requests = {
            cpu    = "20m"
            memory = "16Mi"
          }

          limits = {
            cpu    = "50m"
            memory = "32Mi"
          }
        }
      }

      admissionWebhooks = {
        patch = {
          priorityClassName = ""

          nodeSelector = {
            "kubernetes.io/os" = "linux"
            "lnrs.io/tier"     = "system"
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
        }

        certManager = {
          enabled = true
        }
      }
    }

    prometheus = {
      prometheusSpec = {
        retention = "28d"

        remoteWrite = var.prometheus_remote_write

        podMonitorSelector = {
          matchLabels = {
            "lnrs.io/monitoring-platform" = "true"
          }
        }

        serviceMonitorSelector = {
          matchLabels = {
            "lnrs.io/monitoring-platform" = "true"
          }
        }

        ruleSelector = {
          matchLabels = {
            "lnrs.io/monitoring-platform" = "true"
            "lnrs.io/prometheus-rule"     = "true"
          }
        }

        logLevel  = "info"
        logFormat = "json"

        priorityClassName = ""

        nodeSelector = {
          "kubernetes.io/os" = "linux"
          "lnrs.io/tier"     = "system"
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

        podAntiAffinity            = "hard"
        podAntiAffinityTopologyKey = "topology.kubernetes.io/zone"

        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = "azure-disk-premium-ssd-delete"

              accessModes : [
                "ReadWriteOnce"
              ]

              resources = {
                requests = {
                  storage = "500Gi"
                }
              }
            }
          }
        }

        resources = {
          requests = {
            cpu    = "500m"
            memory = "4096Mi"
          }

          limits = {
            cpu    = "2000m"
            memory = "4096Mi"
          }
        }
      }

      ingress = {
        enabled          = true
        annotations      = var.ingress_annotations
        ingressClassName = var.ingress_class_name
        pathType         = "Prefix"
        hosts            = ["prometheus-${var.ingress_subdomain_suffix}.${var.ingress_domain}"]
        tls = [{
          hosts = ["prometheus-${var.ingress_subdomain_suffix}.${var.ingress_domain}"]
        }]
      }
    }

    alertmanager = {
      alertmanagerSpec = {
        priorityClassName = ""

        retention = "120h"

        nodeSelector = {
          "kubernetes.io/os" = "linux"
          "lnrs.io/tier"     = "system"
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

        storage = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = "azure-disk-premium-ssd-delete"

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

        receivers = local.alertmanager_receivers

        route = {
          group_by = [
            "namespace",
            "severity"
          ]
          group_wait      = "30s"
          group_interval  = "5m"
          repeat_interval = "12h"
          receiver        = "null"

          routes = local.alertmanager_routes
        }
      }

      ingress = {
        enabled          = true
        annotations      = var.ingress_annotations
        ingressClassName = var.ingress_class_name
        pathType         = "Prefix"
        hosts            = ["alertmanager-${var.ingress_subdomain_suffix}.${var.ingress_domain}"]
        tls = [{
          hosts = ["alertmanager-${var.ingress_subdomain_suffix}.${var.ingress_domain}"]
        }]
      }
    }

    grafana = {
      enabled = true

      rbac = {
        create     = true
        pspEnabled = false
      }

      podLabels = {
        aadpodidbinding = module.identity_grafana.name
      }

      admin = {
        existingSecret = kubernetes_secret.grafana_auth.metadata[0].name
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

        azure = {
          managed_identity_enabled = true
        }
      }

      plugins = distinct(concat([
        "grafana-piechart-panel"
      ], var.grafana_additional_plugins))

      additionalDataSources = concat([local.grafana_azure_monitor_data_source], var.grafana_additional_data_sources)

      priorityClassName = ""

      nodeSelector = {
        "kubernetes.io/os" = "linux"
        "lnrs.io/tier"     = "system"
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

      ingress = {
        enabled          = true
        annotations      = var.ingress_annotations
        ingressClassName = var.ingress_class_name
        pathType         = "Prefix"
        path             = "/"
        hosts            = ["grafana-${var.ingress_subdomain_suffix}.${var.ingress_domain}"]
        tls = [{
          hosts = ["grafana-${var.ingress_subdomain_suffix}.${var.ingress_domain}"]
        }]
      }

      resources = {
        requests = {
          cpu    = "100m"
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
            cpu    = "100m"
            memory = "128Mi"
          }

          limits = {
            cpu    = "200m"
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
      create = false
    }

    ## Deploy servicemonitor
    kubeStateMetrics = {
      enabled = true
    }

    kube-state-metrics = {
      podSecurityPolicy = {
        enabled = false
      }

      prometheus = {
        monitor = {
          enabled = true
          additionalLabels = {
            "lnrs.io/monitoring-platform" = "true"
          }
        }
      }

      priorityClassName = ""

      nodeSelector = {
        "kubernetes.io/os" = "linux"
        "lnrs.io/tier"     = "system"
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

    nodeExporter = {
      enabled = true
    }

    prometheus-node-exporter = {
      rbac = {
        create     = true
        pspEnabled = false
      }

      prometheus = {
        monitor = {
          enabled = true
          additionalLabels = {
            "lnrs.io/monitoring-platform" = "true"
          }
        }
      }

      priorityClassName = "system-node-critical"

      nodeSelector = {
        "kubernetes.io/os" = "linux"
      }

      tolerations = [{
        operator = "Exists"
      }]

      updateStrategy = {
        type = "RollingUpdate"

        rollingUpdate = {
          maxUnavailable = "25%"
        }
      }

      resources = {
        requests = {
          cpu    = "100m"
          memory = "32Mi"
        }

        limits = {
          cpu    = "500m"
          memory = "128Mi"
        }
      }
    }
  }

  alertmanager_base_receivers    = [{ name = "null" }]
  alertmanager_default_receivers = length(var.alertmanager_receivers) > 0 ? [] : [{ name = "alerts" }]
  alertmanager_receivers         = concat(local.alertmanager_base_receivers, local.alertmanager_default_receivers, var.alertmanager_receivers)

  alertmanager_base_routes    = [{ match = { alertname = "Watchdog" }, receiver = "null" }]
  alertmanager_default_routes = length(var.alertmanager_routes) > 0 ? [] : [{ match_re = { severity = "warning|critical" }, receiver = "alerts" }]
  alertmanager_routes         = concat(local.alertmanager_base_routes, local.alertmanager_default_routes, var.alertmanager_routes)

  loki_data_source = {
    name   = "Loki"
    type   = "loki"
    url    = "http://loki-gateway.logging.svc.cluster.local"
    access = "proxy"
    orgId  = "1"
  }

  grafana_azure_monitor_data_source = {
    name      = "Azure Monitor"
    type      = "grafana-azure-monitor-datasource"
    orgId     = "1"
    isDefault = false
    jsonData = {
      subscriptionId = var.subscription_id
    }
  }

  resource_group_id                             = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  oms_log_analytics_workspace_resource_group_id = var.oms_agent && length(var.oms_log_analytics_workspace_id) > 0 ? regex("([[:ascii:]]*)(/providers/)", var.oms_log_analytics_workspace_id)[0] : ""

  crd_files           = { for x in fileset(path.module, "crds/*.yaml") : basename(x) => "${path.module}/${x}" }
  resource_files      = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
  dashboard_templates = { for x in fileset(path.module, "resources/configmap-dashboard-*.yaml.tpl") : basename(x) => { path = "${path.module}/${x}", vars = { resource_id = var.control_plane_log_analytics_workspace_id, subscription_id = var.subscription_id } } }
}
