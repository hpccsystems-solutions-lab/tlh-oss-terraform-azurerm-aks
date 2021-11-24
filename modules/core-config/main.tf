resource "kubernetes_namespace" "default" {
  depends_on = [time_sleep.namespace]

  for_each = toset(local.namespaces)

  metadata {
    name = each.key

    labels = {
      name = each.key
    }
  }

  lifecycle {
    ignore_changes = all
  }
}

module "storage_classes" {
  source = "./modules/storage-classes"
}

module "local_storage" {
  source = "./modules/local-storage"

  depends_on = [module.storage_classes]
}

resource "time_sleep" "namespace" {
  destroy_duration = "30s"
}

module "rbac" {
  depends_on = [kubernetes_namespace.default]

  cluster_id              = var.cluster_id
  azuread_clusterrole_map = var.azuread_clusterrole_map

  source = "./modules/rbac"
}

##############################################################################################
## Deploy separately as many services have a dependency on these CRDs, i.e. servicemonitors ##

resource "kubectl_manifest" "kube_prometheus_stack_crds" {
  for_each = { for x in fileset(path.module, "modules/kube-prometheus-stack/crds/*.yaml") : basename(x) => "${path.module}/${x}" }

  yaml_body = file(each.value)
}

###################################################################
## Use pod_identity as the anchor module to enforce dependencies ##

module "pod_identity" {
  depends_on = [
    kubernetes_namespace.default,
    module.storage_classes,
    kubectl_manifest.kube_prometheus_stack_crds
  ]

  source = "./modules/pod-identity"

  resource_group_name          = var.resource_group_name
  namespace                    = "kube-system"
  aks_identity                 = var.aks_identity
  aks_node_resource_group_name = var.aks_node_resource_group_name
  azure_subscription_id        = var.azure_subscription_id
  network_plugin               = var.network_plugin
}

module "external_dns" {
  depends_on = [module.pod_identity]

  source = "./modules/external-dns"

  azure_tenant_id       = var.azure_tenant_id
  azure_subscription_id = var.azure_subscription_id
  azure_environment     = local.external_dns.azure_environment

  resource_group_name     = var.resource_group_name
  resource_group_location = var.location
  cluster_name            = var.cluster_name

  private_domain_filters = {
    names               = local.external_dns.private_zones
    resource_group_name = local.external_dns.private_resource_group_name
  }

  public_domain_filters = {
    names               = local.external_dns.public_zones
    resource_group_name = local.external_dns.public_resource_group_name
  }

  additional_sources = local.external_dns.additional_sources

  tags = var.tags
}

module "cert_manager" {
  depends_on = [module.pod_identity]

  source = "./modules/cert-manager"

  azure_subscription_id   = var.azure_subscription_id
  cluster_name            = var.cluster_name
  resource_group_name     = var.resource_group_name
  resource_group_location = var.location
  tags                    = var.tags

  letsencrypt_environment = local.cert_manager.letsencrypt_environment
  dns_zones               = local.cert_manager.dns_zones
  additional_issuers      = local.cert_manager.additional_issuers
  default_issuer_kind     = local.cert_manager.default_issuer_kind
  default_issuer_name     = local.cert_manager.default_issuer_name
  azure_environment       = local.cert_manager.azure_environment

  ingress_internal_core_domain = local.ingress_internal_core.domain
}

module "ingress_internal_core" {
  depends_on = [module.cert_manager]

  source = "./modules/ingress_internal_core"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  lb_source_cidrs = local.ingress_internal_core.lb_source_cidrs
}

module "kube_prometheus_stack" {
  depends_on = [module.ingress_internal_core]

  source = "./modules/kube-prometheus-stack"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  skip_crds = true

  prometheus_remote_write = local.prometheus.remote_write

  alertmanager_smtp_host = local.alertmanager.smtp_host
  alertmanager_smtp_from = local.alertmanager.smtp_from
  alertmanager_receivers = local.alertmanager.receivers
  alertmanager_routes    = local.alertmanager.routes

  grafana_admin_password          = local.grafana.admin_password
  grafana_plugins                 = local.grafana.additional_plugins
  grafana_additional_data_sources = local.grafana.additional_data_sources

  ingress_domain           = local.ingress_internal_core.domain
  ingress_subdomain_suffix = local.ingress_internal_core.subdomain_suffix

  loki_enabled = local.loki.enabled
}

module "fluent-bit" {
  depends_on = [module.pod_identity]

  source = "./modules/fluent-bit"

  loki_enabled = local.loki.enabled

  tags = var.tags
}

module "fluentd" {
  depends_on = [module.pod_identity]

  source = "./modules/fluentd"

  azure_subscription_id   = var.azure_subscription_id
  location                = var.location

  cluster_name            = var.cluster_name

  image_repository = local.fluentd.image_repository
  image_tag        = local.fluentd.image_tag
  additional_env   = local.fluentd.additional_env
  debug            = local.fluentd.debug
  pod_labels       = local.fluentd.pod_labels
  filters          = local.fluentd.filters
  routes           = local.fluentd.routes
  outputs          = local.fluentd.outputs

  tags = var.tags
}
