locals {
  namespace = "logging"

  chart_version = "2.6.9"

  chart_values = merge({
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

    persistence = {
      enabled      = true
      storageClass = "azure-disk-premium-ssd-retain"
      accessMode   = "ReadWriteOnce"
      size         = "50Gi"
    }

    env = concat([
      { name = "RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR", value = "0.9" },
      { name = "SUBSCRIPTION_ID", value = var.azure_subscription_id },
      { name = "LOCATION", value = var.location },
      { name = "CLUSTER_NAME", value = var.cluster_name }
    ], var.additional_env)

    debug = var.debug

    config = {
      forward = local.forward_config
      filter  = local.filter_config
      route   = local.route_config
      output  = local.output_config
    }
  }, local.image_override)

  image_override = length(var.image_repository) > 0 && length(var.image_tag) > 0 ? {
    image = {
      repository = var.image_repository
      tag        = var.image_tag
    }
  } : {}

  default_route = <<-EOT
    <route **>
      @label @DEFAULT
    </route>
  EOT

  default_output = <<-EOT
    <label @DEFAULT>
      <match **>
        @type null
      </match>
    </label>
  EOT

  forward_config = <<-EOT
    <source>
      @type forward
      @id input
      port 24224
      bind 0.0.0.0
    </source>
  EOT

  filter_config = <<-EOT
    <filter **>
      @type record_transformer
      <record>
        accountId "#{ENV['SUBSCRIPTION_ID']}"
        region "#{ENV['LOCATION']}"
        clusterName "#{ENV['CLUSTER_NAME']}"
      </record>
    </filter>
    %{if length(var.filters) > 0~}
    ${var.filters}
    %{endif~}
  EOT

  route_config = <<-EOT
    <match **>
      @type route
      <route **>
        copy
        @label @PROMETHEUS
      </route>
      ${indent(2, length(var.routes) > 0 ? var.routes : local.default_route)}
    </match>
  EOT

  output_config = length(var.outputs) > 0 ? var.outputs : local.default_output

  resource_files   = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
  resource_objects = {}
}
