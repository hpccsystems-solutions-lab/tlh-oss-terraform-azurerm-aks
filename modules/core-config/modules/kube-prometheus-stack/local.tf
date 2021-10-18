locals {
  namespace = "monitoring"

  chart_version = "16.12.1"

  chart_values = {
    commonLabels = {
      "lnrs.io/k8s-platform" = "true"
    }

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
    ### Prometheus ################################

    prometheus = {
      ingress = {
        enabled = true

        ingressClassName = "core-internal"
        pathType         = "Prefix"

        hosts = ["prometheus-${var.ingress_subdomain_suffix}.${var.ingress_domain}"]
        tls = [{
          "hosts" = ["prometheus-${var.ingress_subdomain_suffix}.${var.ingress_domain}"]
        }]
      }

      prometheusSpec = {
        retention = "28d"

        podMetadata = {
          labels = {
            "lnrs.io/k8s-platform" = "true"
          }
        }

        priorityClassName = "system-cluster-critical"

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
    }
    ### End of Prometheus #########################
    ###############################################

    ###############################################
    ### AlertManager ##############################

    alertmanager = {
      alertmanagerSpec = {
        podMetadata = {
          labels = {
            "lnrs.io/k8s-platform" = "true"
          }
        }

        priorityClassName = "system-cluster-critical"

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

      createCustomResource = false
      manageCrds           = false

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
    ### Node Exporter #############################

    ## Deploy servicemonitor
    nodeExporter = {
      enabled = true
    }

    prometheus-node-exporter = {
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

    ###############################################
    ### Kube-state-metrics ########################

    ## Deploy servicemonitor
    kubeStateMetrics = {
      enabled = true
    }

    kube-state-metrics = {
      priorityClassName = "system-cluster-critical"

      podSecurityPolicy = {
        enabled = false
      }

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

      ## Avoid duplicate kube-state-metrics servicemonitor
      prometheus = {
        monitor = {
          enabled = false
          additionalLabels = {
            "lnrs.io/monitoring-platform" = "core-prometheus"
          }
        }
      }

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
