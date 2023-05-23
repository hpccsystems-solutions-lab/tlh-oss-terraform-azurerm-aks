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

  timeouts = var.timeouts

  depends_on = [
    module.crds,
    module.pre_upgrade,
    module.storage,
    module.fluentd
  ]
}

module "fluentd" {
  source = "./modules/fluentd"

  subscription_id         = var.subscription_id
  location                = var.location
  resource_group_name     = var.resource_group_name
  cluster_name            = var.cluster_name
  cluster_oidc_issuer_url = var.cluster_oidc_issuer_url
  namespace               = kubernetes_namespace.default["logging"].metadata[0].name
  labels                  = var.labels
  zones                   = local.az_count
  image_repository        = var.core_services_config.fluentd.image_repository
  image_tag               = var.core_services_config.fluentd.image_tag
  additional_env          = var.core_services_config.fluentd.additional_env
  debug                   = var.core_services_config.fluentd.debug
  filters                 = var.core_services_config.fluentd.filters
  route_config            = var.core_services_config.fluentd.route_config
  loki                    = var.experimental.loki
  systemd_logs_loki       = var.experimental.systemd_logs_loki
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
  control_plane_log_analytics_enabled      = var.core_services_config.logging.control_plane.log_analytics_enabled
  control_plane_log_analytics_workspace_id = var.core_services_config.logging.control_plane.log_analytics_wokspace_id
  oms_agent_enabled                        = var.core_services_config.oms_agent.enabled
  oms_agent_log_analytics_workspace_id     = var.core_services_config.oms_agent.log_analytics_wokspace_id
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
    module.ingress_internal_core
  ]
}

module "loki" {
  source = "./modules/loki"
  count  = var.experimental.loki ? 1 : 0

  subscription_id         = var.subscription_id
  location                = var.location
  resource_group_name     = var.resource_group_name
  cluster_name            = var.cluster_name
  cluster_oidc_issuer_url = var.cluster_oidc_issuer_url
  namespace               = kubernetes_namespace.default["logging"].metadata[0].name
  labels                  = var.labels
  subnet_id               = var.subnet_id
  zones                   = local.az_count
  tags                    = var.tags
  timeouts                = var.timeouts

  depends_on = [
    module.crds,
    module.pre_upgrade,
    module.storage,
    module.aad_pod_identity,
    module.cert_manager,
    module.ingress_internal_core,
    module.kube_prometheus_stack
  ]
}

module "local_static_provisioner" {
  count = var.core_services_config.storage.local ? 1 : 0

  source = "./modules/local-static-provisioner"

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
