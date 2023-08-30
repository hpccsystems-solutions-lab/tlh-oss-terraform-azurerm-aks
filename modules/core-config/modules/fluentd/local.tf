locals {
  name          = "fluentd"
  chart_version = "3.10.0"

  cluster_version_minor = tonumber(regex("^1\\.(\\d+)", var.cluster_version)[0])

  location_sanitized = lower(replace(var.location, " ", ""))

  use_aad_workload_identity = false

  chart_values = {
    nameOverride = local.name

    image = var.image_repository != null && var.image_tag != null ? {
      repository = var.image_repository
      tag        = var.image_tag
      } : {
      tagPrefix = "glibc"
    }

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

    podLabels = merge(var.labels, local.use_aad_workload_identity ? {} : {
      aadpodidbinding = module.identity.name
    })

    podAnnotations = {
      "fluentbit.io/exclude" = "true"
    }

    service = {
      annotations = {
        "service.kubernetes.io/topology-aware-hints" = "auto"
      }
    }

    serviceMonitor = {
      enabled = true
      additionalLabels = {
        "lnrs.io/monitoring-platform" = "true"
      }
    }

    dashboards = {
      enabled = true
    }

    replicaCount = var.zones

    podDisruptionBudget = {
      enabled        = true
      maxUnavailable = 1
    }

    priorityClassName = "system-cluster-critical"

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

    affinity = {
      podAntiAffinity = {
        requiredDuringSchedulingIgnoredDuringExecution = concat([{
          topologyKey = "kubernetes.io/hostname"
          }], local.cluster_version_minor >= 27 ? [] : [{
          topologyKey = "topology.kubernetes.io/zone"
        }])
      }
    }

    topologySpreadConstraints = local.cluster_version_minor >= 27 ? [{
      maxSkew            = 1
      minDomains         = var.zones
      topologyKey        = "topology.kubernetes.io/zone"
      whenUnsatisfiable  = "DoNotSchedule"
      nodeAffinityPolicy = "Honor"
      nodeTaintsPolicy   = "Honor"
    }] : []

    resources = {
      requests = {
        cpu    = "${coalesce(try(var.resource_overrides.fluentd_default.cpu, null), "500")}m"
        memory = "${coalesce(try(var.resource_overrides.fluentd_default.memory, null), "512")}Mi"
      }
      limits = {
        cpu    = "${coalesce(try(var.resource_overrides.fluentd_default.cpu_limit, null), "1000")}m"
        memory = "${coalesce(try(var.resource_overrides.fluentd_default.memory, null), "512")}Mi"
      }
    }

    persistence = {
      enabled      = true
      legacy       = true
      storageClass = "azure-disk-premium-ssd-delete"
      accessMode   = "ReadWriteOnce"
      size         = "64Gi"
    }

    env = [for k, v in local.additional_env : { name = k, value = v }]

    configuration = {
      port        = 24224
      bindAddress = "0.0.0.0"

      system = {
        rootDir = "/fluentd/state"

        additionalConfig = {
          log_level = local.log_level_lookup[var.log_level]
        }
      }

      filters = local.filter_config_string

      routes = local.route_config

      debug = false
    }

  }

  additional_env = merge({
    "RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR" = "0.9"
    "SUBSCRIPTION_ID"                     = var.subscription_id
    "LOCATION"                            = local.location_sanitized
    "CLUSTER_NAME"                        = var.cluster_name
  }, var.additional_env)

  loki_route_config = {
    match  = var.loki_nodes_output.enabled && var.loki_workloads_output.enabled ? "**" : (var.loki_nodes_output.enabled ? "host.**" : "kube.**")
    label  = "@LOKI"
    copy   = true
    config = <<-EOT
      <filter kube.**>
        @type grep
        <exclude>
          key $['annotations']['lnrs.io/loki-ignore']
          pattern /^true$/
        </exclude>
      </filter>
      <match **>
        @type loki
        url "http://${coalesce(var.loki_nodes_output.host, var.loki_workloads_output.host, "NULL")}:${tostring(coalesce(var.loki_nodes_output.port, var.loki_workloads_output.port, -1))}"
        line_format "json"
        extract_kubernetes_labels false
        <label>
          cluster
          namespace
          app
        </label>
        <buffer>
          @type file
          path /fluentd/state/loki
          flush_mode interval
          flush_interval 10s
          chunk_limit_size 2MB
          total_limit_size 8GB
          overflow_action drop_oldest_chunk
          retry_type exponential_backoff
          retry_timeout 168h
        </buffer>
      </match>
    EOT
  }

  azure_storage_nodes_route_config = var.azure_storage_nodes_output.enabled ? {
    match  = "host.**"
    label  = "@AZURE_NODES"
    copy   = true
    config = <<-EOT
      <match **>
        @type azurestorage_gen2
        azure_storage_account         ${regex("[[:alnum:]]+$", var.azure_storage_nodes_output.id)}
        azure_container               ${var.azure_storage_nodes_output.container}
        azure_instance_msi            ${module.identity.id}
        azure_client_id               ${module.identity.client_id}
        azure_object_key_format       %%{path}/%%{time_slice}_$${chunk_id}.%%{file_extension}
        time_slice_format             %Y%m%d-%H
        path                          "${join("/", compact([var.azure_storage_nodes_output.path_prefix, "kubernetes/${var.cluster_name}/%Y/%m/%d"]))}"
        auto_create_container         true
        store_as                      gzip
        format                        json
        <buffer time>
          @type file
          path /fluentd/state/azurestorage/nodes
          timekey 900
          timekey_wait 60
          timekey_use_utc true
          chunk_limit_size 128MB
          total_limit_size 8GB
          overflow_action drop_oldest_chunk
          retry_type exponential_backoff
          retry_forever true
        </buffer>
      </match>
    EOT
  } : {}

  azure_storage_workloads_route_config = var.azure_storage_workloads_output.enabled ? {
    match  = "kube.**"
    label  = "@AZURE_WORKLOADS"
    copy   = true
    config = <<-EOT
      <match **>
        @type azurestorage_gen2
        azure_storage_account         ${regex("[[:alnum:]]+$", var.azure_storage_workloads_output.id)}
        azure_container               ${var.azure_storage_workloads_output.container}
        azure_instance_msi            ${module.identity.id}
        azure_client_id               ${module.identity.client_id}
        azure_object_key_format       %%{path}/%%{time_slice}_$${chunk_id}.%%{file_extension}
        time_slice_format             %Y%m%d-%H
        path                          "${join("/", compact([var.azure_storage_workloads_output.path_prefix, "kubernetes/${var.cluster_name}/%Y/%m/%d"]))}"
        auto_create_container         true
        store_as                      gzip
        format                        json
        <buffer time>
          @type file
          path /fluentd/state/azurestorage/workloads
          timekey 900
          timekey_wait 60
          timekey_use_utc true
          chunk_limit_size 128MB
          total_limit_size 8GB
          overflow_action drop_oldest_chunk
          retry_type exponential_backoff
          retry_forever true
        </buffer>
      </match>
    EOT
  } : {}

  route_config = concat((var.loki_nodes_output.enabled || var.loki_workloads_output.enabled) ? [local.loki_route_config] : [], var.azure_storage_nodes_output.enabled ? [local.azure_storage_nodes_route_config] : [], var.azure_storage_workloads_output.enabled ? [local.azure_storage_workloads_route_config] : [], length(var.route_config) == 0 || var.debug ? [{
    match  = "**"
    label  = length(var.route_config) > 0 ? "@DEBUG" : "@DEFAULT"
    copy   = length(var.route_config) > 0
    config = <<-EOT
      <match **>
        @type ${var.debug ? "stdout" : "null"}
      </match>
    EOT
  }] : [], var.route_config)

  filter_config_string = <<EOT
%{if length(var.extra_records) > 0~}
<filter **>
  @type record_transformer
  <record>
%{for k, v in var.extra_records~}
    ${k} ${replace(v, "/(?i)\\$\\{([a-z0-9_]+)\\}/", "#{ENV['$n']}")}
%{endfor~}
  </record>
</filter>
%{endif~}
%{if var.filters != null~}
${trimspace(var.filters)}
%{endif~}
EOT

  storage_account_ids = distinct(compact(concat(var.azure_storage_nodes_output.enabled ? [var.azure_storage_nodes_output.id] : [], var.azure_storage_workloads_output.enabled ? [var.azure_storage_workloads_output.id] : [])))

  service_account_name = local.name

  log_level_lookup = {
    "ERROR" = "error"
    "WARN"  = "warn"
    "INFO"  = "info"
    "DEBUG" = "debug"
  }

  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
}
