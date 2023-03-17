locals {
  chart_version = "3.7.0"

  use_aad_workload_identity = false

  chart_values = {
    nameOverride = "fluentd"

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

      labels = var.workload_identity && local.use_aad_workload_identity ? {
        "azure.workload.identity/use" = "true"
      } : {}

      annotations = var.workload_identity && local.use_aad_workload_identity ? {
        "azure.workload.identity/client-id" = module.identity.id
      } : {}
    }

    podLabels = merge(var.labels, var.workload_identity && local.use_aad_workload_identity ? {} : {
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
    "LOCATION"                            = var.location
    "CLUSTER_NAME"                        = var.cluster_name
  }, var.additional_env)

  route_config = concat(length(var.route_config) == 0 || var.debug ? [{
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

  service_account_name = "fluentd"

  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
}
