resource "kubernetes_namespace" "default" {
  for_each = toset(local.namespaces)

  metadata {
    name = each.key

    labels = merge(var.labels, local.namespace_pod_security_labels)
  }
}

resource "kubernetes_labels" "system_namespace" {
  for_each = toset(local.system_namespaces)

  api_version = "v1"
  kind        = "Namespace"

  metadata {
    name = each.key
  }

  labels = local.namespace_pod_security_labels
}

module "crds" {
  source = "./modules/crds"

  modules = [
    "aad-pod-identity",
    "cert-manager",
    "external-dns",
    "kube-prometheus-stack"
  ]
}

module "storage" {
  source = "./modules/storage"

  labels = var.labels
}

module "pre_upgrade" {
  source = "./modules/pre-upgrade"

  subscription_id     = var.subscription_id
  resource_group_name = var.resource_group_name
  cluster_name        = var.cluster_name

  depends_on = [
    kubernetes_namespace.default,
    kubernetes_labels.system_namespace,
    module.crds,
    module.storage
  ]
}

module "aad_pod_identity" {
  source = "./modules/aad-pod-identity"

  subscription_id          = var.subscription_id
  resource_group_name      = var.resource_group_name
  node_resource_group_name = var.node_resource_group_name
  cni                      = var.cni
  kubelet_identity_id      = var.kubelet_identity_id
  namespace                = kubernetes_labels.system_namespace["kube-system"].metadata[0].name
  labels                   = var.labels
  log_level                = var.logging.workloads.core_service_log_level

  timeouts = var.timeouts

  experimental_finalizer_wait = var.experimental.aad_pod_identity_finalizer_wait

  depends_on = [
    module.crds,
    module.pre_upgrade
  ]
}

module "cert_manager" {
  source = "./modules/cert-manager"

  azure_environment         = local.azure_environment
  tenant_id                 = var.tenant_id
  subscription_id           = var.subscription_id
  location                  = var.location
  resource_group_name       = var.resource_group_name
  dns_resource_group_lookup = var.dns_resource_group_lookup
  cluster_name              = var.cluster_name
  cluster_oidc_issuer_url   = var.cluster_oidc_issuer_url
  namespace                 = kubernetes_namespace.default["cert-manager"].metadata[0].name
  labels                    = var.labels
  log_level                 = var.logging.workloads.core_service_log_level
  acme_dns_zones            = distinct(concat([local.ingress_internal_core.domain], coalesce(var.core_services_config.cert_manager.acme_dns_zones, [])))
  additional_issuers        = var.core_services_config.cert_manager.additional_issuers
  default_issuer_kind       = var.core_services_config.cert_manager.default_issuer_kind
  default_issuer_name       = var.core_services_config.cert_manager.default_issuer_name
  tags                      = var.tags

  timeouts = var.timeouts

  depends_on = [
    module.crds,
    module.pre_upgrade,
    module.aad_pod_identity
  ]
}

module "coredns" {
  source = "./modules/coredns"

  namespace     = kubernetes_labels.system_namespace["kube-system"].metadata[0].name
  labels        = var.labels
  forward_zones = var.core_services_config.coredns.forward_zones

  depends_on = [
    module.crds,
    module.pre_upgrade
  ]
}

module "external_dns" {
  source = "./modules/external-dns"

  azure_environment         = local.azure_environment
  tenant_id                 = var.tenant_id
  subscription_id           = var.subscription_id
  location                  = var.location
  resource_group_name       = var.resource_group_name
  dns_resource_group_lookup = var.dns_resource_group_lookup
  cluster_name              = var.cluster_name
  cluster_oidc_issuer_url   = var.cluster_oidc_issuer_url
  namespace                 = kubernetes_namespace.default["dns"].metadata[0].name
  labels                    = var.labels
  log_level                 = var.logging.workloads.core_service_log_level
  additional_sources        = var.core_services_config.external_dns.additional_sources
  private_domain_filters    = local.ingress_internal_core.public_dns ? var.core_services_config.external_dns.private_domain_filters : distinct(concat([local.ingress_internal_core.domain], coalesce(var.core_services_config.external_dns.private_domain_filters, [])))
  public_domain_filters     = local.ingress_internal_core.public_dns ? distinct(concat([local.ingress_internal_core.domain], var.core_services_config.external_dns.public_domain_filters)) : coalesce(var.core_services_config.external_dns.public_domain_filters, [])
  tags                      = var.tags

  timeouts = var.timeouts

  depends_on = [
    module.crds,
    module.pre_upgrade,
    module.aad_pod_identity
  ]
}

module "fluent_bit" {
  source = "./modules/fluent-bit"

  location     = var.location
  cluster_name = var.cluster_name

  namespace = kubernetes_namespace.default["logging"].metadata[0].name
  labels    = var.labels
  log_level = var.logging.workloads.core_service_log_level

  aggregator              = var.core_services_config.fluent_bit_aggregator.enabled ? "fluent-bit" : "fluentd"
  aggregator_host         = var.core_services_config.fluent_bit_aggregator.enabled ? module.fluent_bit_aggregator[0].host : module.fluentd[0].host
  aggregator_forward_port = var.core_services_config.fluent_bit_aggregator.enabled ? module.fluent_bit_aggregator[0].forward_port : module.fluentd[0].forward_port

  multiline_parsers = var.experimental.fluent_bit_collector_multiline_parsers
  parsers           = var.experimental.fluent_bit_collector_parsers

  timeouts = var.timeouts

  depends_on = [
    module.crds,
    module.pre_upgrade,
    module.storage,
    module.fluent_bit_aggregator,
    module.fluentd
  ]
}


module "fluent_bit_aggregator" {
  source = "./modules/fluent-bit-aggregator"
  count  = var.core_services_config.fluent_bit_aggregator.enabled ? 1 : 0

  subscription_id         = var.subscription_id
  location                = var.location
  resource_group_name     = var.resource_group_name
  cluster_name            = var.cluster_name
  cluster_oidc_issuer_url = var.cluster_oidc_issuer_url
  namespace               = kubernetes_namespace.default["observability"].metadata[0].name
  labels                  = var.labels
  log_level               = var.logging.workloads.core_service_log_level
  zones                   = local.az_count
  replicas_per_zone       = var.core_services_config.fluent_bit_aggregator.replicas_per_zone
  cpu_requests_override   = var.experimental.fluent_bit_aggregator_cpu_requests_override
  cpu_limits_override     = var.experimental.fluent_bit_aggregator_cpu_limits_override
  memory_override         = var.experimental.fluent_bit_aggregator_memory_override
  extra_env               = var.core_services_config.fluent_bit_aggregator.extra_env
  secret_env              = var.core_services_config.fluent_bit_aggregator.secret_env
  extra_records           = var.logging.extra_records
  lua_scripts             = var.core_services_config.fluent_bit_aggregator.lua_scripts
  loki_output             = local.loki_output
  raw_filters             = var.core_services_config.fluent_bit_aggregator.raw_filters
  raw_outputs             = var.core_services_config.fluent_bit_aggregator.raw_outputs
  tags                    = var.tags

  timeouts = var.timeouts

  depends_on = [
    module.crds,
    module.pre_upgrade,
    module.storage,
    module.aad_pod_identity,
    module.loki
  ]
}

module "fluentd" {
  source = "./modules/fluentd"
  count  = var.core_services_config.fluent_bit_aggregator.enabled ? 0 : 1

  subscription_id         = var.subscription_id
  location                = var.location
  resource_group_name     = var.resource_group_name
  cluster_name            = var.cluster_name
  cluster_oidc_issuer_url = var.cluster_oidc_issuer_url
  namespace               = kubernetes_namespace.default["logging"].metadata[0].name
  labels                  = var.labels
  log_level               = var.logging.workloads.core_service_log_level
  zones                   = local.az_count
  image_repository        = var.core_services_config.fluentd.image_repository
  image_tag               = var.core_services_config.fluentd.image_tag
  additional_env          = var.core_services_config.fluentd.additional_env
  extra_records           = var.logging.extra_records
  debug                   = var.core_services_config.fluentd.debug
  filters                 = var.core_services_config.fluentd.filters
  route_config            = var.core_services_config.fluentd.route_config
  loki_output             = local.loki_output
  azure_storage_output    = local.azure_storage_output
  tags                    = var.tags

  timeouts = var.timeouts

  experimental_memory_override = var.experimental.fluentd_memory_override

  depends_on = [
    module.crds,
    module.pre_upgrade,
    module.storage,
    module.aad_pod_identity,
    module.loki
  ]
}

module "ingress_internal_core" {
  source = "./modules/ingress-internal-core"

  namespace               = kubernetes_namespace.default["ingress-core-internal"].metadata[0].name
  labels                  = var.labels
  log_level               = var.logging.workloads.core_service_log_level
  ingress_node_group      = var.ingress_node_group
  lb_source_cidrs         = local.ingress_internal_core.lb_source_cidrs
  lb_subnet_name          = local.ingress_internal_core.lb_subnet_name == null ? null : local.ingress_internal_core.lb_subnet_name
  domain                  = local.ingress_internal_core.domain
  certificate_issuer_kind = module.cert_manager.default_issuer_kind
  certificate_issuer_name = module.cert_manager.default_issuer_name

  timeouts = var.timeouts

  depends_on = [
    module.crds,
    module.pre_upgrade,
    module.cert_manager
  ]
}

module "kube_prometheus_stack" {
  source = "./modules/kube-prometheus-stack"

  subscription_id                          = var.subscription_id
  location                                 = var.location
  resource_group_name                      = var.resource_group_name
  cluster_name                             = var.cluster_name
  cluster_oidc_issuer_url                  = var.cluster_oidc_issuer_url
  namespace                                = kubernetes_namespace.default["monitoring"].metadata[0].name
  labels                                   = var.labels
  log_level                                = var.logging.workloads.core_service_log_level
  subnet_id                                = var.subnet_id
  zones                                    = local.az_count
  prometheus_remote_write                  = var.core_services_config.prometheus.remote_write
  alertmanager_smtp_host                   = var.core_services_config.alertmanager.smtp_host
  alertmanager_smtp_from                   = var.core_services_config.alertmanager.smtp_from
  alertmanager_receivers                   = var.core_services_config.alertmanager.receivers
  alertmanager_routes                      = var.core_services_config.alertmanager.routes
  grafana_admin_password                   = var.core_services_config.grafana.admin_password
  grafana_additional_plugins               = var.core_services_config.grafana.additional_plugins
  grafana_additional_data_sources          = var.core_services_config.grafana.additional_data_sources
  control_plane_log_analytics_enabled      = var.logging.control_plane.log_analytics.enabled
  control_plane_log_analytics_workspace_id = var.logging.control_plane.log_analytics.workspace_id
  loki                                     = local.loki_output
  oms_agent_enabled                        = var.core_services_config.oms_agent.enabled
  oms_agent_log_analytics_workspace_id     = var.core_services_config.oms_agent.log_analytics_workspace_id
  ingress_class_name                       = module.ingress_internal_core.ingress_class_name
  ingress_domain                           = local.ingress_internal_core.domain
  ingress_subdomain_suffix                 = local.ingress_internal_core.subdomain_suffix
  ingress_annotations                      = local.ingress_internal_core.annotations
  tags                                     = var.tags

  timeouts = var.timeouts

  experimental_prometheus_memory_override = var.experimental.prometheus_memory_override

  depends_on = [
    module.crds,
    module.pre_upgrade,
    module.storage,
    module.aad_pod_identity,
    module.cert_manager,
    module.loki,
    module.ingress_internal_core
  ]
}

module "local_static_provisioner" {
  source = "./modules/local-static-provisioner"
  count  = var.storage.nvme_pv.enabled ? 1 : 0

  namespace = kubernetes_labels.system_namespace["kube-system"].metadata[0].name
  labels    = var.labels

  timeouts = var.timeouts

  depends_on = [
    module.crds,
    module.pre_upgrade
  ]
}

module "loki" {
  source = "./modules/loki"
  count  = var.core_services_config.loki.enabled ? 1 : 0

  subscription_id         = var.subscription_id
  location                = var.location
  resource_group_name     = var.resource_group_name
  cluster_name            = var.cluster_name
  cluster_oidc_issuer_url = var.cluster_oidc_issuer_url
  namespace               = kubernetes_namespace.default["logging"].metadata[0].name
  labels                  = var.labels
  log_level               = var.logging.workloads.core_service_log_level
  subnet_id               = var.subnet_id
  zones                   = local.az_count
  tags                    = var.tags
  timeouts                = var.timeouts

  depends_on = [
    module.crds,
    module.pre_upgrade,
    module.storage,
    module.aad_pod_identity,
    module.cert_manager
  ]
}

module "node_config" {
  source = "./modules/node-config"
  count  = var.storage.host_path.enabled ? 1 : 0

  namespace = kubernetes_labels.system_namespace["kube-system"].metadata[0].name
  labels    = var.labels

  timeouts = var.timeouts

  depends_on = [
    module.crds,
    module.pre_upgrade
  ]
}

module "oms_agent" {
  source = "./modules/oms-agent"
  count  = var.core_services_config.oms_agent.enabled ? 1 : 0

  namespace                   = kubernetes_labels.system_namespace["kube-system"].metadata[0].name
  labels                      = var.labels
  manage_config               = var.core_services_config.oms_agent.manage_config
  core_namespaces             = concat([kubernetes_labels.system_namespace["kube-system"].metadata[0].name], local.namespaces)
  containerlog_schema_version = var.core_services_config.oms_agent.containerlog_schema_version
}
