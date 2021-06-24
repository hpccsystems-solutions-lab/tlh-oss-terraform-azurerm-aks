module "priority_classes" {
  source = "./modules/priority-classes"

  additional_priority_classes = var.additional_priority_classes
}

module "storage_classes" {
  source = "./modules/storage-classes"

  additional_storage_classes = var.additional_storage_classes
}

resource "time_sleep" "namespace" {
  destroy_duration = "30s"
}

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

resource "kubernetes_secret" "default" {
  depends_on = [kubernetes_namespace.default]

  for_each = var.secrets

  metadata {
    name      = each.value.name
    namespace = each.value.namespace
  }

  type = each.value.type
  data = each.value.data
}

resource "kubernetes_config_map" "default" {
  depends_on = [kubernetes_namespace.default]

  for_each = var.configmaps

  metadata {
    name      = each.value.name
    namespace = each.value.namespace
  }

  data = each.value.data
}

module "rbac" {
  depends_on = [kubernetes_namespace.default]

  cluster_id               = var.cluster_id
  azuread_clusterrole_map  = var.azuread_clusterrole_map

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
    module.priority_classes,
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

  resource_group_name     = var.resource_group_name
  resource_group_location = var.location
  cluster_name            = var.cluster_name
  dns_zones               = var.external_dns_zones

  tolerations = [{
    key      = "CriticalAddonsOnly"
    operator = "Equal"
    value    = "true"
    effect   = "NoSchedule"
  }]

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
  letsencrypt_email       = local.cert_manager.letsencrypt_email

  dns_zones = local.cert_manager.dns_zones

  additional_issuers = local.cert_manager.additional_issuers
}

module "ingress_core_internal" {
  depends_on = [module.pod_identity]

  source = "./modules/ingress-core-internal"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  lb_cidrs         = local.ingress_core_internal.lb_cidrs
  lb_source_cidrs  = local.ingress_core_internal.lb_source_cidrs
  min_replicas     = local.ingress_core_internal.min_replicas
  max_replicas     = local.ingress_core_internal.max_replicas
}

module "kube_prometheus_stack" {
  depends_on = [module.pod_identity]

  source = "./modules/kube-prometheus-stack"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  skip_crds = true

  prometheus_storage_class_name = local.prometheus.storage_class_name
  prometheus_remote_write       = local.prometheus.remote_write

  alertmanager_storage_class_name = local.alertmanager.storage_class_name
  alertmanager_smtp_host          = local.alertmanager.smtp_host
  alertmanager_smtp_from          = local.alertmanager.smtp_from
  alertmanager_receivers          = local.alertmanager.receivers
  alertmanager_routes             = local.alertmanager.routes

  grafana_admin_password          = local.grafana.admin_password
  grafana_plugins                 = local.grafana.plugins
  grafana_additional_data_sources = local.grafana.additional_data_sources

  create_ingress      = local.internal_ingress_enabled
  ingress_domain      = local.internal_ingress_domain
  ingress_annotations = local.internal_ingress_annotations

  loki_enabled = local.loki.enabled
}
