locals {
  name          = "fluentd"
  chart_version = "3.8.0"

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
        requiredDuringSchedulingIgnoredDuringExecution = [{
          topologyKey = "topology.kubernetes.io/zone"
        }]
      }
    }

    resources = {
      requests = {
        cpu    = "500m"
        memory = coalesce(var.experimental_memory_override, "512Mi")
      }

      limits = {
        cpu    = "1000m"
        memory = coalesce(var.experimental_memory_override, "512Mi")
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
    match  = var.loki_systemd_logs ? "**" : "kube.**"
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
        url "http://${var.loki_host}:${tostring(var.loki_port)}"
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

  route_config = concat(var.loki ? [local.loki_route_config] : [], length(var.route_config) == 0 || var.debug ? [{
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
%{if var.filters != null~}
${trimspace(var.filters)}
%{endif~}
EOT

  service_account_name = local.name

  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
}
