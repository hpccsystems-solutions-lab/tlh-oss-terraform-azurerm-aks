locals {
  chart_version = "0.39.0"

  location_sanitized = lower(replace(var.location, " ", ""))

  chart_values = {
    serviceMonitor = {
      enabled = true
      selector = {
        "lnrs.io/monitoring-platform" = "true"
      }
    }

    service = {
      labels = var.labels
    }

    dashboards = {
      enabled = true
    }

    updateStrategy = {
      type = "RollingUpdate"

      rollingUpdate = {
        maxUnavailable = "25%"
      }
    }

    resources = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }

      limits = {
        cpu    = "1000m"
        memory = "128Mi"
      }
    }

    nodeSelector = {
      "kubernetes.io/os" = "linux"
    }

    tolerations = [{
      operator = "Exists"
    }]

    labels = var.labels

    podLabels = var.labels

    podAnnotations = {
      "fluentbit.io/exclude" = "true"
    }

    priorityClassName = "system-node-critical"

    daemonSetVolumes = [
      {
        name = "logs"
        hostPath = {
          path = "/var/log"
        }
      },
      {
        name = "containers"
        hostPath = {
          path = "/var/lib/docker/containers"
        }
      },
      {
        name = "machine-id"
        hostPath = {
          path = "/etc/machine-id"
          type = "File"
        }
      }
    ]

    daemonSetVolumeMounts = [
      {
        name      = "logs"
        mountPath = "/var/log"
        readOnly  = true
      },
      {
        name      = "containers"
        mountPath = "/var/lib/docker/containers"
        readOnly  = true
      },
      {
        name      = "machine-id"
        mountPath = "/etc/machine-id"
        readOnly  = true
      }
    ]

    extraVolumes = [
      {
        name = "state"
        hostPath = {
          path = "/var/fluent-bit/state"
        }
      }
    ]

    extraVolumeMounts = [
      {
        name      = "state"
        mountPath = "/var/fluent-bit/state"
      }
    ]

    config = {
      customParsers = local.custom_parsers
      service       = local.service_config
      inputs        = local.input_config
      filters       = local.filter_config
      outputs       = local.output_config
    }

    luaScripts = {
      "filters.lua" = file("${path.module}/resources/filters.lua")
    }

    hotReload = {
      enabled = true

      resources = {
        requests = {
          cpu    = "10m"
          memory = "16Mi"
        }

        limits = {
          cpu    = "1000m"
          memory = "16Mi"
        }
      }
    }
  }

  multiline_parser_filters = flatten([for k, v in var.multiline_parsers : [for x in v.workloads : {
    match  = "kube.${x.namespace}.${x.pod_prefix}*"
    parser = k
  }]])

  custom_parsers = <<EOT
[PARSER]
    name   kubernetes-tag
    format regex
    regex  ^(?<namespace_name>[^.]+)\.(?<pod_name>[^.]+)\.(?<container_name>[^.]+)
%{for k, v in var.parsers}
[PARSER]
    name          ${k}
    format        regex
    regex         ${v.pattern}
    types         ${join(" ", [for k, v in v.types : "${k}:${v}"])}
%{endfor~}
%{for k, v in var.multiline_parsers}
[MULTILINE_PARSER]
    name          ${k}
    type          regex
    flush_timeout 5s
%{for rule in v.rules~}
    rule "${rule.name}" "${rule.pattern}" "${rule.next_rule_name}"
%{endfor~}
%{endfor~}
EOT

  service_config = <<-EOT
    [SERVICE]
        daemon                    false
        log_level                 ${local.log_level_lookup[var.log_level]}
        parsers_file              parsers.conf
        parsers_file              custom_parsers.conf
        flush                     5
        grace                     5
        scheduler.base            5
        scheduler.cap             30
        storage.path              /var/fluent-bit/state/flb-storage/
        storage.sync              normal
        storage.checksum          false
        storage.max_chunks_up     128
        storage.backlog.mem_limit 8MB
        storage.metrics           true
        http_server               true
        http_listen               0.0.0.0
        http_Port                 2020
  EOT

  input_config = <<-EOT
    [INPUT]
        name                     systemd
        systemd_filter           _SYSTEMD_UNIT=docker.service
        systemd_filter           _SYSTEMD_UNIT=containerd.service
        systemd_filter           _SYSTEMD_UNIT=kubelet.service
        tag                      host.*
        strip_underscores        true
        lowercase                true
        db                       /var/fluent-bit/state/flb-storage/systemd.db
        db.sync                  normal
        storage.type             filesystem

    [INPUT]
        name                     tail
        path                     /var/log/containers/*.log
        tag_regex                (?<pod_name>[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*)_(?<namespace_name>[^_]+)_(?<container_name>.+)-
        tag                      kube.<namespace_name>.<pod_name>.<container_name>
        read_from_head           true
        refresh_interval         10
        rotate_wait              30
        multiline.parser         cri
        skip_long_lines          true
        skip_empty_lines         true
        static_batch_size        8M
        buffer_chunk_size        32KB
        buffer_max_size          32KB
        db                       /var/fluent-bit/state/flb-storage/tail-containers.db
        db.sync                  normal
        db.locking               true
        db.journal_mode          wal
        storage.type             filesystem
  EOT

  filter_config = <<EOT
%{for filter in local.multiline_parser_filters~}
[FILTER]
    name                  multiline
    match                 ${filter.match}
    multiline.key_content log
    multiline.parser      ${filter.parser}
    mode                  parser
    buffer                false
    flush_ms              2000

%{endfor~}

[FILTER]
    name   lua
    match  host.*
    script /fluent-bit/scripts/filters.lua
    call   HostRecordModifier

[FILTER]
    name                kubernetes
    match               kube.*
    kube_tag_prefix     kube.
    regex_parser        kubernetes-tag
    merge_log           true
    merge_log_trim      true
    keep_log            false
    k8s-logging.parser  true
    k8s-logging.exclude true
    kube_token_ttl      600

[FILTER]
    name   lua
    match  kube.*
    script /fluent-bit/scripts/filters.lua
    call   KubeRecordModifier

EOT
  output_config = <<EOT
[OUTPUT]
    name                     forward
    match                    *
    host                     ${var.aggregator_host}
    port                     ${tostring(var.aggregator_forward_port)}
    fluentd_compat           ${var.aggregator == "fluentd" ? "true" : "false"}
    send_options             false
    require_ack_response     true
    %{~if var.aggregator == "fluent-bit"~}
    compress                 gzip
    %{~endif~}
    workers                  2
    retry_limit              false
    storage.total_limit_size 16GB
EOT

  log_level_lookup = {
    "ERROR" = "error"
    "WARN"  = "warn"
    "INFO"  = "info"
    "DEBUG" = "debug"
  }

  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
}
