locals {
  namespace = "logging"

  chart_version = "0.19.19"

  chart_values = {
    serviceMonitor = {
      enabled = true
      selector = {
        "lnrs.io/monitoring-platform" = "core-prometheus"
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

    podLabels = {
      "lnrs.io/k8s-platform" = "true"
    }

    podAnnotations = {
      "fluentbit.io/exclude" = "true"
    }

    priorityClassName = "system-node-critical"

    config = {
      service = local.service_config
      inputs  = local.input_config
      filters = local.filter_config
      outputs = var.loki_enabled ? "${local.output_config}\n${local.output_config_loki}" : local.output_config
    }
  }

  service_config = <<-EOT
    [SERVICE]
      Daemon                    Off
      Flush                     1
      Log_Level                 info
      HTTP_Server               On
      HTTP_Listen               0.0.0.0
      HTTP_Port                 2020
      storage.path              /var/log/flb-storage/
      storage.sync              normal
      storage.checksum          off
      storage.max_chunks_up     128
      storage.backlog.mem_limit 16M
      storage.metrics           on
      Parsers_File              parsers.conf
      Parsers_File              custom_parsers.conf
  EOT

  input_config = <<-EOT
    [INPUT]
      Name              tail
      Path              /var/log/containers/*.log
      Parser            cri
      Tag               kube.*
      Skip_Long_Lines   On
      Buffer_Chunk_Size 32k
      Buffer_Max_Size   256k
      DB                /var/log/flb-storage/tail.db
      DB.Sync           normal
      storage.type      filesystem

    [INPUT]
      Name              systemd
      Systemd_Filter    _SYSTEMD_UNIT=docker.service
      Systemd_Filter    _SYSTEMD_UNIT=containerd.service
      Systemd_Filter    _SYSTEMD_UNIT=kubelet.service
      Tag               host.*
      Strip_Underscores On
      DB                /var/log/flb-storage/systemd.db
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

    [FILTER]
      Name         nest
      Match        kube.*
      Operation    lift
      Nested_under kubernetes
      Add_prefix   kubernetes_

    [FILTER]
      Name         nest
      Match        kube.*
      Operation    lift
      Nested_under kubernetes_labels
      Add_prefix   kubernetes_labels_

    [FILTER]
      Name         nest
      Match        kube.*
      Operation    lift
      Nested_under kubernetes_annotations
      Add_prefix   kubernetes_annotations_
  EOT

  output_config = <<-EOT
    [OUTPUT]
      Name  forward
      Match *
      Host  fluentd.logging.svc
      Port  24224
  EOT

  output_config_loki = <<-EOT
    [OUTPUT]
      Name loki
      Match kube.*
      Host loki.logging.svc
      Port 3100
      labels job=fluent-bit, host=$kubernetes['host'], namespace=$kubernetes['namespace_name'], pod=$kubernetes['pod_name'], container=$kubernetes['container_name']
      auto_kubernetes_labels off
      line_format json
      net.connect_timeout 180
  EOT

  resource_files = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
  resource_objects = {}
}
