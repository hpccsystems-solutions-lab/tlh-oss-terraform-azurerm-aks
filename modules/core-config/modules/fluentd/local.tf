locals {
  namespace = "logging"

  chart_version = "2.4.0"

  chart_values = {
    nameOverride = "fluentd"

    podLabels: var.podlabels

    podAnnotations = {
      "fluentbit.io/exclude" = "true"
    }

    priorityClassName = "lnrs-platform-critical"

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

    replicaCount = 3

    nodeSelector = {
      "kubernetes.io/os" = "linux"
    }

    affinity = {
      podAntiAffinity = {
        requiredDuringSchedulingIgnoredDuringExecution = [{
          labelSelector = {
            matchExpressions = [{
              key      = "app"
              operator = "In"
              values = [
                "fluentd"
              ]
            }]
          }
          topologyKey = "topology.kubernetes.io/zone"
        }]
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