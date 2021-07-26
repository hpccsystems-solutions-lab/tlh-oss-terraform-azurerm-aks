locals {
  namespace = "logging"

  chart_version = "2.5.1"

  chart_values = {
    nameOverride = "fluentd"

    podLabels = merge({
      "lnrs.io/k8s-platform" = "true"
    }, var.pod_labels)

    podAnnotations = {
      "fluentbit.io/exclude" = "true"
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

    dashboards = {
      enabled = true
    }

    persistence = {
      enabled      = true
      storageClass = "azure-disk-premium-ssd-retain"
      accessMode   = "ReadWriteOnce"
      size         = "50Gi"
    }

    replicaCount = 3

    podDisruptionBudget = {
      enabled        = true
      maxUnavailable = 1
    }

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

    affinity = {
      podAntiAffinity = {
        requiredDuringSchedulingIgnoredDuringExecution = [{
          labelSelector = {
            matchLabels = {
              "app.kubernetes.io/name"     = "fluentd"
              "app.kubernetes.io/instance" = "fluentd"
            }
          }
          topologyKey = "topology.kubernetes.io/zone"
        }]
      }
    }

    resources = {
      requests = {
        cpu    = "100m"
        memory = "256Mi"
      }

      limits = {
        cpu    = "500m"
        memory = "512Mi"
      }
    }

    env = concat([{ name = "RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR", value = "0.9" }], var.additional_env)

    debug = var.debug

    config = {
      filter = var.filter_config
      route  = var.route_config
      output = var.output_config
    }
  }

  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
}
