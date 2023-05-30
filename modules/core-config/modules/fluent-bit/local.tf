locals {
  chart_version = "0.30.2"

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
      service = local.service_config
      inputs  = local.input_config
      filters = local.filter_config
      outputs = local.output_config
    }
  }

  service_config = <<-EOT
    [SERVICE]
      daemon                    false
      log_level                 info
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
      tag                      host.*
      systemd_filter           _SYSTEMD_UNIT=docker.service
      systemd_filter           _SYSTEMD_UNIT=containerd.service
      systemd_filter           _SYSTEMD_UNIT=kubelet.service
      strip_underscores        true
      lowercase                true
      db                       /var/fluent-bit/state/flb-storage/systemd.db
      db.sync                  normal
      mem_buf_limit            8MB
      storage.type             filesystem

    [INPUT]
      name                     tail
      tag                      kube.*
      path                     /var/log/containers/*.log
      read_from_head           true
      refresh_interval         10
      rotate_wait              30
      multiline.parser         cri
      skip_long_lines          true
      skip_empty_lines         true
      buffer_chunk_size        32KB
      buffer_max_size          32KB
      db                       /var/fluent-bit/state/flb-storage/tail-containers.db
      db.sync                  normal
      db.locking               true
      db.journal_mode          wal
      mem_buf_limit            8MB
      storage.type             filesystem
  EOT

  filter_config = <<-EOT
    [FILTER]
      name   record_modifier
      match  *
      record cloud azure
      record location ${local.location_sanitized}
      record cluster ${var.cluster_name}

    [FILTER]
      name  modify
      match host.*
      copy  hostname node
      copy  systemd_unit app
      add   namespace _

    [FILTER]
      name                kubernetes
      match               kube.*
      merge_log           true
      merge_log_trim      true
      keep_log            false
      k8s-logging.parser  true
      k8s-logging.exclude true
      kube_token_ttl      600

    [FILTER]
      name         nest
      match        kube.*
      operation    lift
      nested_under kubernetes
      add_prefix   kubernetes_

    [FILTER]
      name         nest
      match        kube.*
      operation    lift
      nested_under kubernetes_labels
      add_prefix   kubernetes_label_

    [FILTER]
      name         nest
      match        kube.*
      operation    lift
      nested_under kubernetes_annotations
      add_prefix   kubernetes_annotation_

    [FILTER]
      name  modify
      match kube.*
      copy  kubernetes_host node
      copy  kubernetes_namespace_name namespace
      copy  kubernetes_pod_name pod
      copy  kubernetes_container_name container
      copy  kubernetes_container_hash containerHash
      copy  kubernetes_container_image containerImage
      copy  kubernetes_label_app.kubernetes.io/name app
      copy  kubernetes_label_app app
      copy  kubernetes_pod_name app
      copy  kubernetes_label_app.kubernetes.io/instance instance
      copy  kubernetes_namespace_name instance
      copy  kubernetes_label_app.kubernetes.io/component component
      copy  kubernetes_label_app.kubernetes.io/part-of partOf
      copy  kubernetes_label_app.kubernetes.io/version version

    [FILTER]
      name          nest
      match         kube.*
      operation     nest
      wildcard      kubernetes_label_*
      nest_under    labels
      remove_prefix kubernetes_label_

    [FILTER]
      name          nest
      match         kube.*
      operation     nest
      wildcard      kubernetes_annotation_*
      nest_under    annotations
      remove_prefix kubernetes_annotation_

    [FILTER]
      name         modify
      match        kube.*
      remove       _p
      remove       stream
      remove_regex ^kubernetes\_.+
  EOT


  output_config = <<-EOT
    [OUTPUT]
      name                     forward
      match                    *
      host                     fluentd.logging.svc.cluster.local
      port                     24224
      fluentd_compat           true
      send_options             false
      require_ack_response     true
      workers                  2
      retry_limit              false
      storage.total_limit_size 16GB
  EOT

  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
}
