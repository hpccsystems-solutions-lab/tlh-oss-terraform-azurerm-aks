locals {
  namespace = "monitoring"

  chart_version = "30.1.0"

  grafana_identity_name = "grafana"

  chart_values = {
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

    ###############################################
    ### Prometheus Operator #######################

    prometheusOperator = {
      enabled = true

      podLabels = {
        "lnrs.io/k8s-platform" = "true"
      }

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

      resources = {
        requests = {
          cpu    = "50m"
          memory = "128Mi"
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
    ### End of Prometheus Operator ################
    ###############################################

    ###############################################
    ### Prometheus ################################

    prometheus = {
      prometheusSpec = {
        retention = "28d"

        podMetadata = {
          labels = {
            "lnrs.io/k8s-platform" = "true"
          }
        }

        remoteWrite = var.prometheus_remote_write

        podMonitorSelector = {
          matchLabels = {
            "lnrs.io/monitoring-platform" = "core-prometheus"
          }
        }

        serviceMonitorSelector = {
          matchLabels = {
            "lnrs.io/monitoring-platform" = "core-prometheus"
          }
        }

        ruleSelector = {
          matchLabels = {
            "lnrs.io/monitoring-platform" = "core-prometheus"
          }
        }

        logLevel  = "info"
        logFormat = "json"

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

        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = "azure-disk-premium-ssd-retain"

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
            memory = "4096Mi"
          }

          limits = {
            cpu    = "2000m"
            memory = "6144Mi"
          }
        }
      }

      ingress = {
        enabled = true

        ingressClassName = "core-internal"
        pathType         = "Prefix"

        hosts = ["prometheus-${var.ingress_subdomain_suffix}.${var.ingress_domain}"]
        tls = [{
          "hosts" = ["prometheus-${var.ingress_subdomain_suffix}.${var.ingress_domain}"]
        }]
      }
    }
    ### End of Prometheus #########################
    ###############################################

    ###############################################
    ### AlertManager ##############################

    alertmanager = {
      alertmanagerSpec = {
        priorityClassName = "system-cluster-critical"

        podMetadata = {
          labels = {
            "lnrs.io/k8s-platform" = "true"
          }
        }

        retention = "120h"

        nodeSelector = {
          "kubernetes.io/os"          = "linux"
          "kubernetes.azure.com/mode" = "system"
        }

        tolerations = [{
          key      = "CriticalAddonsOnly"
          operator = "Exists"
          effect   = "NoSchedule"
        }]

        storage = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = "azure-disk-premium-ssd-retain"

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
        enabled = true

        ingressClassName = "core-internal"
        pathType         = "Prefix"

        hosts = ["alertmanager-${var.ingress_subdomain_suffix}.${var.ingress_domain}"]
        tls = [{
          "hosts" = ["alertmanager-${var.ingress_subdomain_suffix}.${var.ingress_domain}"]
        }]
      }
    }
    ### End of AlertManager #######################
    ###############################################

    ###############################################
    ### Grafana ###################################

    grafana = {
      enabled = true

      rbac = {
        create     = true
        pspEnabled = false
      }

      podLabels = {
        aadpodidbinding        = "${var.cluster_name}-${local.grafana_identity_name}"
        "lnrs.io/k8s-platform" = "true"
      }

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

        azure = {
          managed_identity_enabled = true
        }
      }

      plugins = var.grafana_plugins

      additionalDataSources = concat(var.loki_enabled ? [local.grafana_loki_data_source] : [], [local.grafana_azure_monitor_data_source], var.grafana_additional_data_sources)

      priorityClassName = ""

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

      ingress = {
        enabled = true

        ingressClassName = "core-internal"
        pathType         = "Prefix"
        path             = "/"

        hosts = ["grafana-${var.ingress_subdomain_suffix}.${var.ingress_domain}"]
        tls = [{
          "hosts" = ["grafana-${var.ingress_subdomain_suffix}.${var.ingress_domain}"]
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
    ### End of Grafana ############################
    ###############################################

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

    ###############################################
    ### Kube-state-metrics ########################

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
            "lnrs.io/monitoring-platform" = "core-prometheus"
          }
        }
      }

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

      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }

        limits = {
          cpu    = "500m"
          memory = "1024Mi"
        }
      }

      collectors = [
        "certificatesigningrequests",
        "configmaps",
        "cronjobs",
        "daemonsets",
        "deployments",
        "endpoints",
        "horizontalpodautoscalers",
        "ingresses",
        "jobs",
        "limitranges",
        "mutatingwebhookconfigurations",
        "namespaces",
        "networkpolicies",
        "nodes",
        "persistentvolumeclaims",
        "persistentvolumes",
        "poddisruptionbudgets",
        "pods",
        "replicasets",
        "replicationcontrollers",
        "resourcequotas",
        "secrets",
        "services",
        "statefulsets",
        "storageclasses",
        "validatingwebhookconfigurations",
        "volumeattachments"
      ]
    }
    ### End of Kube-state-metrics #################
    ###############################################

    ###############################################
    ### Node Exporter #############################

    ## Deploy servicemonitor
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
            "lnrs.io/monitoring-platform" = "core-prometheus"
          }
        }
      }
      podLabels = {
        "lnrs.io/k8s-platform" = "true"
      }

      priorityClassName = "system-node-critical"

      nodeSelector = {
        "kubernetes.io/os" = "linux"
      }

      tolerations = [
        {
          operator = "Exists"
        }
      ]

      updateStrategy = {
        type = "RollingUpdate"

        rollingUpdate = {
          maxUnavailable = "25%"
        }
      }

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
    ### End of Node Exporter ######################
    ###############################################

  }

  grafana_auth_secret_name = "grafana-auth"

  grafana_loki_data_source = {
    name   = "Loki"
    type   = "loki"
    url    = "http://loki.logging.svc:3100"
    access = "proxy"
    orgId  = "1"
  }

  grafana_azure_monitor_data_source = {
    name   = "Azure Monitor"
    type   = "grafana-azure-monitor-datasource"
    orgId  = "1"
    isDefault = false
    jsonData = {
      subscriptionId = var.azure_subscription_id
    }
  }

  crd_files      = { for x in fileset(path.module, "crds/*.yaml") : basename(x) => "${path.module}/${x}" }
  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
}
