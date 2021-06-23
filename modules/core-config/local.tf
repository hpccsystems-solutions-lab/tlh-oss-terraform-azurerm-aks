locals {
  core_namespaces = [
    "cert-manager",
    "cluster-health",
    "dns",
    "logging",
    "ingress-core-internal",
    "monitoring"
  ]

  namespaces = concat(local.core_namespaces, var.namespaces)

  ########################
  ## Ingress Controller ##

  ingress_core_internal = merge({
    lb_cidrs         = [ "10.0.0.0/8" ]
    lb_source_cidrs  = [ "10.0.0.0/8", "100.65.0.0/16" ]
    min_replicas     = 3
    max_replicas     = 6
  }, lookup(var.config, "ingress_core_internal", {}))


  #####################
  ## Service ingress ##

  internal_ingress_tmp = merge({
    domain               = ""
    dns_subdomain_suffix = var.cluster_name
    tags                 = ""
  }, lookup(var.config, "internal_ingress", {}))

  internal_ingress_domain  = local.internal_ingress_tmp.domain
  internal_ingress_enabled = length(local.internal_ingress_domain) > 0
  internal_ingress_annotations = {
    "cert-manager.io/cluster-issuer" = "letsencrypt-issuer"
  }


  ##############
  ## Services ##

  loki = merge({
    enabled = false
  }, lookup(var.config, "loki", {}))

  prometheus = merge({
    storage_class_name = "azure-disk-premium-ssd-retain"
    remote_write       = []
  }, lookup(var.config, "prometheus", {}))

  grafana = merge({
    admin_password          = "changeme"
    additional_data_sources = []
    plugins                 = ["grafana-piechart-panel"]
  }, lookup(var.config, "grafana", {}))

  alertmanager = merge({
    storage_class_name = "azure-disk-premium-ssd-retain"
    smtp_host          = ""
    smtp_from          = ""
    receivers          = [{ name = "alerts" }]
    routes             = [{ match_re = { severity = "warning|critical" }, receiver = "alerts" }]
  }, lookup(var.config, "alertmanager", {}))
}
