locals {
  name          = "loki"
  chart_version = "5.5.3"

  azure_cli_image_version = "2.9.1"

  use_aad_workload_identity = false

  chart_values = {
    nameOverride = local.name

    global = {
      priorityClassName = ""
    }

    serviceAccount = {
      enabled = true
      name    = local.service_account_name

      labels = local.use_aad_workload_identity ? {
        "azure.workload.identity/use" = "true"
      } : {}

      annotations = local.use_aad_workload_identity ? {
        "azure.workload.identity/client-id" = module.identity.id
      } : {}
    }

    loki = {
      podAnnotations = {
        "fluentbit.io/exclude" = "true"
      }

      podLabels = var.labels
      analytics = {
        reporting_enabled = false
      }
      auth_enabled = false
      commonConfig = {
        path_prefix        = "/var/loki"
        replication_factor = 2
      }
      compactor = {
        shared_store           = "azure"
        working_directory      = "/var/loki/compactor"
        retention_enabled      = true
        retention_delete_delay = "2h"
      }
      ingester = {
        max_chunk_age        = "2h"
        chunk_idle_period    = "30m"
        chunk_block_size     = 262144
        chunk_target_size    = 1572864
        chunk_retain_period  = "0s"
        max_transfer_retries = 0
      }
      limits_config = {
        enforce_metric_name           = false
        reject_old_samples            = true
        reject_old_samples_max_age    = "168h"
        max_cache_freshness_per_query = "10m"
        split_queries_by_interval     = "15m"
      }
      server = {
        log_level        = "info"
        http_listen_port = 3100
      }
      schemaConfig = {
        configs = [{
          from = "2023-01-01"
          index = {
            period = "24h"
            prefix = "index_"
          }
          object_store = "azure"
          schema       = "v12"
          store        = "tsdb"
        }]
      }
      storage = {
        type = "azure"
        azure = {
          accountName    = azurerm_storage_account.data.name
          userAssignedId = module.identity.client_id
        }
        bucketNames = {
          chunks = local.storage_container_name
          ruler  = local.storage_container_name
          admin  = local.storage_container_name
        }
      }
      storage_config = {
        azure = {
          container_name = local.storage_container_name
        }
        hedging = {
          at             = "250ms"
          max_per_second = 20
          up_to          = 3
        }
        tsdb_shipper = {
          active_index_directory = "/var/loki/tsdb-index"
          cache_location         = "/var/loki/tsdb-cache"
          cache_ttl              = "24h"
          shared_store           = "azure"
        }
        filesystem = {
          directory = "/var/loki/chunks"
        }
      }
    }

    monitoring = {
      serviceMonitor = {
        enabled = true
        labels = {
          "lnrs.io/monitoring-platform" = "true"
        }
      }
      rules = {
        labels = {
          "lnrs.io/monitoring-platform" = "true"
        }
      }
      selfMonitoring = {
        enabled = false
        grafanaAgent = {
          installOperator = false
        }
      }
      lokiCanary = {
        enabled = false
      }
      dashboards = {
        enabled   = true
        namespace = var.namespace
        labels = {
          "grafana_dashboard"           = "1"
          "lnrs.io/monitoring-platform" = "true"
        }
      }
    }

    memberlist = {
      service = {
        publishNotReadyAddresses = true
      }
    }

    # Type: StatefulSet
    backend = merge({
      replicas = var.zones

      priorityClassName = "system-cluster-critical"

      serviceLabels = var.labels

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
      # NOTE: Use required anti affinity for stateful set. Topology must be set to zone over host.
      affinity = jsonencode({
        podAntiAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = [{
            labelSelector = {
              matchLabels = {
                "app.kubernetes.io/name"      = local.name
                "app.kubernetes.io/instance"  = local.name
                "app.kubernetes.io/component" = "backend"
              }
            }
            topologyKey = "topology.kubernetes.io/zone"
          }]
          preferredDuringSchedulingIgnoredDuringExecution = []
        }
      })

      maxUnavailable = 1

      persistence = {
        storageClass = "azure-disk-premium-ssd-delete"
        size         = "10Gi"
      }

      resources = {
        requests = {
          cpu    = "100m"
          memory = "512Mi"
        }

        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }
    }, local.additional_config, local.init_config)

    # Type: StatefulSet
    write = merge({
      replicas = var.zones

      priorityClassName = "system-cluster-critical"

      serviceLabels = var.labels

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

      affinity = jsonencode({
        podAntiAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = [{
            labelSelector = {
              matchLabels = {
                "app.kubernetes.io/name"      = local.name
                "app.kubernetes.io/instance"  = local.name
                "app.kubernetes.io/component" = "write"
              }
            }
            topologyKey = "topology.kubernetes.io/zone"
          }]
          preferredDuringSchedulingIgnoredDuringExecution = []
        }
      })

      maxUnavailable = 1

      persistence = {
        storageClass = "azure-disk-premium-ssd-delete"
        size         = "30Gi"
      }

      resources = {
        requests = {
          cpu    = "500m"
          memory = "2048Mi"
        }

        limits = {
          cpu    = "1000m"
          memory = "2048Mi"
        }
      }
    }, local.additional_config, local.init_config)

    # Type: Deployment
    read = merge({
      replicas = var.zones

      autoscaling = {
        enabled     = true
        minReplicas = var.zones
        maxReplicas = var.zones * 2
      }

      priorityClassName = "system-cluster-critical"

      serviceLabels = var.labels

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

      affinity = jsonencode({
        podAntiAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = []
          preferredDuringSchedulingIgnoredDuringExecution = [
            {
              podAffinityTerm = {
                labelSelector = {
                  matchLabels = {
                    "app.kubernetes.io/name"      = local.name
                    "app.kubernetes.io/instance"  = local.name
                    "app.kubernetes.io/component" = "read"
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
                    "app.kubernetes.io/name"      = local.name
                    "app.kubernetes.io/instance"  = local.name
                    "app.kubernetes.io/component" = "read"
                  }
                }

                topologyKey = "topology.kubernetes.io/zone"
              }

              weight = 50
            }
          ]
        }
      })

      maxUnavailable = 1

      persistence = {
        storageClass = "azure-disk-premium-ssd-delete"
        size         = "10Gi"
      }

      resources = {
        requests = {
          cpu    = "100m"
          memory = "256Mi"
        }

        limits = {
          cpu    = "1000m"
          memory = "256Mi"
        }
      }
    }, local.additional_config, local.init_config)

    # Type: Deployment
    gateway = {
      enabled = true

      serviceLabels = var.labels

      autoscaling = {
        enabled                        = true
        minReplicas                    = 1
        maxReplicas                    = 3
        targetCPUUtilizationPercentage = 80
      }

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

      affinity = jsonencode({
        podAntiAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = []
          preferredDuringSchedulingIgnoredDuringExecution = [
            {
              podAffinityTerm = {
                labelSelector = {
                  matchLabels = {
                    "app.kubernetes.io/name"      = local.name
                    "app.kubernetes.io/instance"  = local.name
                    "app.kubernetes.io/component" = "gateway"
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
                    "app.kubernetes.io/name"      = local.name
                    "app.kubernetes.io/instance"  = local.name
                    "app.kubernetes.io/component" = "gateway"
                  }
                }

                topologyKey = "topology.kubernetes.io/zone"
              }

              weight = 50
            }
          ]
        }
      })

      resources = {
        requests = {
          cpu    = "100m"
          memory = "256Mi"
        }

        limits = {
          cpu    = "1000m"
          memory = "256Mi"
        }
      }

      ingress = {
        enabled = false
      }
    }

    test = {
      enabled = false
    }
  }

  additional_config = {
    extraArgs = ["-memberlist.bind-addr=$(MY_POD_IP)"]
    extraEnv = [{
      name = "MY_POD_IP"
      valueFrom = {
        fieldRef = { fieldPath = "status.podIP" }
      }
    }]

    podLabels = local.use_aad_workload_identity ? {} : {
      aadpodidbinding = module.identity.name
    }
  }

  init_config = {
    extraVolumes = [{
      name     = "tmp-init"
      emptyDir = {}
    }]

    initContainers = [{
      name  = "storage-containers"
      image = "mcr.microsoft.com/azure-cli:${local.azure_cli_image_version}"

      command = [
        "sh",
        "-c",
        "az login --identity --username $(AZURE_CLIENT_ID) --allow-no-subscriptions;az storage container create --name loki --account-name $(AZURE_STORAGE_ACCOUNT) --auth-mode login"
      ]

      env = [
        {
          name  = "AZURE_CLIENT_ID"
          value = module.identity.client_id
        },
        {
          name  = "AZURE_STORAGE_ACCOUNT"
          value = azurerm_storage_account.data.name
        }
      ]

      volumeMounts = [{
        name      = "tmp-init"
        mountPath = "/.azure"
        readOnly  = false
      }]
    }]
  }

  service_account_name   = local.name
  storage_container_name = local.name
}
