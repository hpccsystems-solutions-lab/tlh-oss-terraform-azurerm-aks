locals {
  name          = "loki"
  chart_version = "5.23.1"

  cluster_version_minor = tonumber(regex("^1\\.(\\d+)", var.cluster_version)[0])

  azure_cli_image_version = "2.9.1"

  use_aad_workload_identity = false

  azure_environment = startswith(var.location, "usgov") ? "AzureUSGovernment" : "AzureCloud"

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
        "azure.workload.identity/client-id" = module.identity.client_id
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
        log_level        = local.log_level_lookup[var.log_level]
        log_format       = "json"
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
          endpointSuffix = substr(replace(azurerm_storage_account.data.primary_blob_host, azurerm_storage_account.data.name, ""), 1, -1)
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
          requiredDuringSchedulingIgnoredDuringExecution = concat([{
            labelSelector = {
              matchLabels = {
                "app.kubernetes.io/name"      = local.name
                "app.kubernetes.io/instance"  = local.name
                "app.kubernetes.io/component" = "backend"
              }
            }
            topologyKey = "kubernetes.io/hostname"
            }], local.cluster_version_minor >= 27 ? [] : [{
            labelSelector = {
              matchLabels = {
                "app.kubernetes.io/name"      = local.name
                "app.kubernetes.io/instance"  = local.name
                "app.kubernetes.io/component" = "backend"
              }
            }
            topologyKey = "topology.kubernetes.io/zone"
          }])
        }
      })

      topologySpreadConstraints = local.cluster_version_minor >= 27 ? jsonencode([
        {
          maxSkew            = 1
          minDomains         = var.zones
          topologyKey        = "topology.kubernetes.io/zone"
          whenUnsatisfiable  = "DoNotSchedule"
          nodeAffinityPolicy = "Honor"
          nodeTaintsPolicy   = "Honor"
          labelSelector = {
            matchLabels = {
              "app.kubernetes.io/name"      = local.name
              "app.kubernetes.io/instance"  = local.name
              "app.kubernetes.io/component" = "backend"
            }
          }
        }
      ]) : null

      maxUnavailable = 1

      persistence = {
        storageClass = "azure-disk-premium-ssd-delete"
        size         = "10Gi"
      }

      resources = {
        requests = {
          cpu    = "${coalesce(try(var.resource_overrides.loki_backend_default.cpu, null), "100")}m"
          memory = "${coalesce(try(var.resource_overrides.loki_backend_default.memory, null), "512")}Mi"
        }
        limits = {
          cpu    = "${coalesce(try(var.resource_overrides.loki_backend_default.cpu_limit, null), "1000")}m"
          memory = "${coalesce(try(var.resource_overrides.loki_backend_default.memory, null), "512")}Mi"
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
          requiredDuringSchedulingIgnoredDuringExecution = concat([{
            labelSelector = {
              matchLabels = {
                "app.kubernetes.io/name"      = local.name
                "app.kubernetes.io/instance"  = local.name
                "app.kubernetes.io/component" = "write"
              }
            }
            topologyKey = "kubernetes.io/hostname"
            }], local.cluster_version_minor >= 27 ? [] : [{
            labelSelector = {
              matchLabels = {
                "app.kubernetes.io/name"      = local.name
                "app.kubernetes.io/instance"  = local.name
                "app.kubernetes.io/component" = "write"
              }
            }
            topologyKey = "topology.kubernetes.io/zone"
          }])
        }
      })

      topologySpreadConstraints = local.cluster_version_minor >= 27 ? jsonencode([
        {
          maxSkew            = 1
          minDomains         = var.zones
          topologyKey        = "topology.kubernetes.io/zone"
          whenUnsatisfiable  = "DoNotSchedule"
          nodeAffinityPolicy = "Honor"
          nodeTaintsPolicy   = "Honor"
          labelSelector = {
            matchLabels = {
              "app.kubernetes.io/name"      = local.name
              "app.kubernetes.io/instance"  = local.name
              "app.kubernetes.io/component" = "write"
            }
          }
        }
      ]) : null

      maxUnavailable = 1

      persistence = {
        storageClass = "azure-disk-premium-ssd-delete"
        size         = "30Gi"
      }

      resources = {
        requests = {
          cpu    = "${coalesce(try(var.resource_overrides.loki_write_default.cpu, null), "500")}m"
          memory = "${coalesce(try(var.resource_overrides.loki_write_default.memory, null), "2048")}Mi"
        }
        limits = {
          cpu    = "${coalesce(try(var.resource_overrides.loki_write_default.cpu_limit, null), "1000")}m"
          memory = "${coalesce(try(var.resource_overrides.loki_write_default.memory, null), "2048")}Mi"
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
          preferredDuringSchedulingIgnoredDuringExecution = concat([
            {
              podAffinityTerm = {
                topologyKey = "kubernetes.io/hostname"
                labelSelector = {
                  matchLabels = {
                    "app.kubernetes.io/name"      = local.name
                    "app.kubernetes.io/instance"  = local.name
                    "app.kubernetes.io/component" = "read"
                  }
                }
              }

              weight = 100
            }], local.cluster_version_minor >= 27 ? [] : [
            {
              podAffinityTerm = {
                topologyKey = "topology.kubernetes.io/zone"
                labelSelector = {
                  matchLabels = {
                    "app.kubernetes.io/name"      = local.name
                    "app.kubernetes.io/instance"  = local.name
                    "app.kubernetes.io/component" = "read"
                  }
                }
              }

              weight = 50
            }
          ])
        }
      })

      topologySpreadConstraints = local.cluster_version_minor >= 27 ? jsonencode([
        {
          maxSkew            = 1
          topologyKey        = "topology.kubernetes.io/zone"
          whenUnsatisfiable  = "ScheduleAnyway"
          nodeAffinityPolicy = "Honor"
          nodeTaintsPolicy   = "Honor"
          labelSelector = {
            matchLabels = {
              "app.kubernetes.io/name"      = local.name
              "app.kubernetes.io/instance"  = local.name
              "app.kubernetes.io/component" = "read"
            }
          }
        }
      ]) : null

      maxUnavailable = 1

      persistence = {
        storageClass = "azure-disk-premium-ssd-delete"
        size         = "10Gi"
      }

      resources = {
        requests = {
          cpu    = "${coalesce(try(var.resource_overrides.loki_read_default.cpu, null), "100")}m"
          memory = "${coalesce(try(var.resource_overrides.loki_read_default.memory, null), "256")}Mi"
        }
        limits = {
          cpu    = "${coalesce(try(var.resource_overrides.loki_read_default.cpu_limit, null), "1000")}m"
          memory = "${coalesce(try(var.resource_overrides.loki_read_default.memory, null), "256")}Mi"
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
          preferredDuringSchedulingIgnoredDuringExecution = concat([
            {
              podAffinityTerm = {
                topologyKey = "kubernetes.io/hostname"
                labelSelector = {
                  matchLabels = {
                    "app.kubernetes.io/name"      = local.name
                    "app.kubernetes.io/instance"  = local.name
                    "app.kubernetes.io/component" = "gateway"
                  }
                }
              }

              weight = 100
            }], local.cluster_version_minor >= 27 ? [] : [
            {
              podAffinityTerm = {
                topologyKey = "topology.kubernetes.io/zone"
                labelSelector = {
                  matchLabels = {
                    "app.kubernetes.io/name"      = local.name
                    "app.kubernetes.io/instance"  = local.name
                    "app.kubernetes.io/component" = "gateway"
                  }
                }
              }

              weight = 50
            }
          ])
        }
      })

      topologySpreadConstraints = local.cluster_version_minor >= 27 ? jsonencode([
        {
          maxSkew            = 1
          topologyKey        = "topology.kubernetes.io/zone"
          whenUnsatisfiable  = "ScheduleAnyway"
          nodeAffinityPolicy = "Honor"
          nodeTaintsPolicy   = "Honor"
          labelSelector = {
            matchLabels = {
              "app.kubernetes.io/name"      = local.name
              "app.kubernetes.io/instance"  = local.name
              "app.kubernetes.io/component" = "gateway"
            }
          }
        }
      ]) : null

      resources = {
        requests = {
          cpu    = "${coalesce(try(var.resource_overrides.loki_gateway_default.cpu, null), "100")}m"
          memory = "${coalesce(try(var.resource_overrides.loki_gateway_default.memory, null), "256")}Mi"
        }
        limits = {
          cpu    = "${coalesce(try(var.resource_overrides.loki_gateway_default.cpu_limit, null), "1000")}m"
          memory = "${coalesce(try(var.resource_overrides.loki_gateway_default.memory, null), "256")}Mi"
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
    podLabels = local.use_aad_workload_identity ? { "azure.workload.identity/use" = "true" } : {
      aadpodidbinding = module.identity.name
    }

    lifecycle = {
      preStop = {
        httpGet = {
          path = "/ingester/flush_shutdown"
          port = "http-metrics"
        }
      }
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
        "az cloud set --name $(AZURE_ENVIRONMENT) > /dev/null 2>&1; az login --identity --username $(AZURE_CLIENT_ID) --allow-no-subscriptions > /dev/null 2>&1; az storage container create --name loki --account-name $(AZURE_STORAGE_ACCOUNT) --auth-mode login"
      ]

      env = [
        {
          name  = "AZURE_CLIENT_ID"
          value = module.identity.client_id
        },
        {
          name  = "AZURE_STORAGE_ACCOUNT"
          value = azurerm_storage_account.data.name
        },
        {
          name  = "AZURE_ENVIRONMENT"
          value = local.azure_environment
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

  log_level_lookup = {
    "ERROR" = "error"
    "WARN"  = "warn"
    "INFO"  = "info"
    "DEBUG" = "debug"
  }
}
