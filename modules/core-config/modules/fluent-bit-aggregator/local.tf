locals {
  name          = "fluent-bit-aggregator"
  chart_version = "0.7.1"

  location_sanitized = lower(replace(var.location, " ", ""))

  use_aad_workload_identity = false

  chart_values = {
    commonLabels = var.labels

    serviceAccount = {
      create = true
      name   = local.service_account_name

      labels = local.use_aad_workload_identity ? {
        "azure.workload.identity/use" = "true"
      } : {}

      annotations = local.use_aad_workload_identity ? {
        "azure.workload.identity/client-id" = module.identity.id
      } : {}
    }

    service = {
      annotations = {
        "service.kubernetes.io/topology-aware-hints" = "auto"
      }

      httpPort = 2020

      additionalPorts = [
        {
          name          = "http-forward"
          port          = 24224
          containerPort = 24224
          protocol      = "TCP"
        }
      ]
    }

    replicas = var.zones * var.replicas_per_zone

    podDisruptionBudget = {
      enabled        = true
      maxUnavailable = 1
    }

    podLabels = merge(var.labels, local.use_aad_workload_identity ? {} : {
      aadpodidbinding = module.identity.name
    })

    podAnnotations = {
      "fluentbit.io/exclude" = "true"
    }

    priorityClassName = "system-cluster-critical"

    terminationGracePeriodSeconds = 60

    env = concat([
      { name = "SUBSCRIPTION_ID", value = var.subscription_id },
      { name = "LOCATION", value = local.location_sanitized },
      { name = "CLUSTER_NAME", value = var.cluster_name }
      ],
      [for k, v in var.extra_env : { name = k, value = v }],
      [for k, v in var.secret_env : { name = k, valueFrom = { secretKeyRef = { name = kubernetes_secret_v1.secret_env[0].metadata[0].name, key = k } } }]
    )

    persistence = {
      enabled       = true
      accessMode    = "ReadWriteOnce"
      storageClass  = "azure-disk-premium-ssd-v2-delete"
      size          = "64Gi"
      retainDeleted = false
      retainScaled  = true
    }

    resources = {
      requests = {
        cpu    = "${coalesce(try(var.resource_overrides.fluent_bit_aggregator_default.cpu, null), "200")}m"
        memory = "${coalesce(try(var.resource_overrides.fluent_bit_aggregator_default.memory, null), "512")}Mi"
      }
      limits = {
        cpu    = "${coalesce(try(var.resource_overrides.fluent_bit_aggregator_default.cpu_limit, null), "1000")}m"
        memory = "${coalesce(try(var.resource_overrides.fluent_bit_aggregator_default.memory, null), "512")}Mi"
      }
    }

    nodeSelector = {
      "kubernetes.io/os" = "linux"
      "lnrs.io/tier"     = "system"
    }

    affinity = {
      podAntiAffinity = {
        preferredDuringSchedulingIgnoredDuringExecution = [
          {
            podAffinityTerm = {
              topologyKey = "kubernetes.io/hostname"
            }

            weight = 100
          },
          {
            podAffinityTerm = {
              topologyKey = "topology.kubernetes.io/zone"
            }

            weight = 50
          }
        ]
      }
    }

    topologySpreadConstraints = []

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

    serviceMonitor = {
      enabled = true
      additionalLabels = {
        "lnrs.io/monitoring-platform" = "true"
      }
    }

    dashboards = {
      enabled = true
    }

    config = {
      storage = true

      service = {
        "log_level"                           = local.log_level_lookup[var.log_level]
        "http_listen"                         = "0.0.0.0"
        "grace"                               = 30
        "storage.sync"                        = "full"
        "storage.checksum"                    = true
        "storage.backlog.mem_limit"           = "128M"
        "storage.delete_irrecoverable_chunks" = true
        "storage.metrics"                     = true
        "storage.max_chunks_up"               = 128
      }

      pipeline = local.pipeline

      luaScripts = var.lua_scripts
    }

    hotReload = {
      enabled = true

      resources = {
        requests = {
          cpu    = "${coalesce(try(var.resource_overrides.fluent_bit_aggregator_reloader.cpu, null), "10")}m"
          memory = "${coalesce(try(var.resource_overrides.fluent_bit_aggregator_reloader.memory, null), "16")}Mi"
        }
        limits = {
          cpu    = "${coalesce(try(var.resource_overrides.fluent_bit_aggregator_reloader.cpu_limit, null), "1000")}m"
          memory = "${coalesce(try(var.resource_overrides.fluent_bit_aggregator_reloader.memory, null), "16")}Mi"
        }
      }
    }
  }

  raw_filters = var.raw_filters != null ? regexall("\\[FILTER\\][^[]+", var.raw_filters) : []
  raw_outputs = var.raw_outputs != null ? regexall("\\[OUTPUT\\][^[]+", var.raw_outputs) : []

  pipeline = <<EOT
[INPUT]
    name                              forward
    listen                            0.0.0.0
    port                              {{ (index .Values.service.additionalPorts 0).containerPort }}
    buffer_chunk_size                 1M
    buffer_max_size                   4M
    storage.type                      filesystem
    storage.pause_on_chunks_overlimit false
%{if length(var.extra_records) > 0}
[FILTER]
    name record_modifier
    match *
%{for k, v in var.extra_records~}
    record ${k} ${v}
%{endfor~}
%{endif~}
%{for filter in local.raw_filters}
${chomp(filter)}
%{endfor~}
%{if var.loki_output.enabled}
[OUTPUT]
    name                     loki
    match                    ${var.loki_output.node_logs && var.loki_output.workload_logs ? "*" : (var.loki_output.node_logs ? "host.*" : "kube.*")}
    host                     ${var.loki_output.host}
    port                     ${tostring(var.loki_output.port)}
    line_format              json
    auto_kubernetes_labels   false
    label_keys               $cluster, $namespace, $app
    storage.total_limit_size 16GB
%{endif~}
%{for output in local.raw_outputs}
${chomp(output)}
%{endfor~}
EOT

  service_account_name = local.name

  log_level_lookup = {
    "ERROR" = "error"
    "WARN"  = "warn"
    "INFO"  = "info"
    "DEBUG" = "debug"
  }

  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
}
