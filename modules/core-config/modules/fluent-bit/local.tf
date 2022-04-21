locals {
  chart_version = "0.19.23"

  chart_values = {
    serviceMonitor = {
      enabled = true
      selector = {
        "lnrs.io/monitoring-platform" = "true"
      }
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
        memory = "64Mi"
      }

      limits = {
        cpu    = "500m"
        memory = "128Mi"
      }
    }

    nodeSelector = {
      "kubernetes.io/os" = "linux"
    }

    tolerations = [{
      operator = "Exists"
    }]

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
      Daemon                    Off
      Log_Level                 info
      storage.path              /var/fluent-bit/state/flb-storage/
      storage.sync              normal
      storage.checksum          off
      storage.max_chunks_up     128
      storage.backlog.mem_limit 16M
      storage.metrics           on
      HTTP_Server               On
      HTTP_Listen               0.0.0.0
      HTTP_Port                 2020
      Flush                     5
      Parsers_File              parsers.conf
      Parsers_File              custom_parsers.conf
  EOT

  input_config = <<-EOT
    [INPUT]
      Name              tail
      Tag               kube.*
      Path              /var/log/containers/*.log
      Read_from_Head    true
      Refresh_Interval  10
      Rotate_Wait       30
      multiline.parser  docker, cri
      Skip_Long_Lines   on
      Skip_Empty_Lines  on
      Buffer_Chunk_Size 32k
      Buffer_Max_Size   256k
      DB                /var/fluent-bit/state/flb-storage/tail-containers.db
      DB.Sync           normal
      DB.locking        true
      DB.journal_mode   wal
      mem_buf_limit     16MB
      storage.type      filesystem

    [INPUT]
      Name              systemd
      Tag               node.*
      Systemd_Filter    _SYSTEMD_UNIT=docker.service
      Systemd_Filter    _SYSTEMD_UNIT=containerd.service
      Systemd_Filter    _SYSTEMD_UNIT=kubelet.service
      Strip_Underscores On
      DB                /var/fluent-bit/state/flb-storage/systemd.db
      DB.Sync           normal
      storage.type      filesystem
  EOT

  filter_config = <<-EOT
    [FILTER]
      Name                kubernetes
      Match               kube.*
      Merge_Log           On
      Merge_Log_Key       log_processed
      Merge_Log_Trim      On
      Keep_Log            On
      K8S-Logging.Parser  On
      K8S-Logging.Exclude On
  EOT

  output_config = <<-EOT
    [OUTPUT]
      Name                     forward
      Match                    *
      Host                     fluentd.logging.svc.cluster.local
      Port                     24224
      storage.total_limit_size 16GB
  EOT

  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
}
