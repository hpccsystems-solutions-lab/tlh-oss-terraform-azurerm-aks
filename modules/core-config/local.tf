locals {
  core_namespaces = [
    "cert-manager",
    "dns",
    "logging",
    "ingress-core-internal",
    "monitoring"
  ]

  namespaces = concat(local.core_namespaces, var.namespaces)

  #############
  ## Ingress ##

  ingress_core_internal = merge({
    domain             = ""
    subdomain_suffix   = var.cluster_name
    lb_source_cidrs    = [ "10.0.0.0/8", "100.65.0.0/16" ]
  }, lookup(var.config, "ingress_core_internal", {}))


  ##############
  ## Services ##

  external_dns = merge({
    additional_sources  = []
    resource_group_name = ""
    zones               = []
  }, lookup(var.config, "external_dns", {}))

  cert_manager = merge({
    letsencrypt_environment = ""
    letsencrypt_email       = ""
    dns_zones               = {}
    additional_issuers      = {}
  }, lookup(var.config, "cert_manager", {}))

  loki = merge({
    enabled = false
  }, lookup(var.config, "loki", {}))

  prometheus = merge({
    remote_write       = []
  }, lookup(var.config, "prometheus", {}))

  grafana = merge({
    admin_password          = "changeme"
    additional_data_sources = []
    additional_plugins      = ["grafana-piechart-panel"]
  }, lookup(var.config, "grafana", {}))

  alertmanager = merge({
    smtp_host          = ""
    smtp_from          = ""
    receivers          = [{ name = "alerts" }]
    routes             = [{ match_re = { severity = "warning|critical" }, receiver = "alerts" }]
  }, lookup(var.config, "alertmanager", {}))

  fluentd = merge({
    additional_env     = []
    debug              = true
    pod_labels         = {}
    filter_config      = ""
    route_config       = <<-EOT
      <match **>
        @type route
        <route **>
          copy
          @label @PROMETHEUS
        </route>
        <route **>
          copy
          @label @DEFAULT
        </route>
      </match>
    EOT
    output_config      = <<-EOT
      <label @DEFAULT>
        <match **>
          @type null
        </match>
      </label>
    EOT
  }, lookup(var.config, "fluentd", {}))
}
