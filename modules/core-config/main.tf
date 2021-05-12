module "priority_classes" {
  source = "./modules/priority-classes"

  additional_priority_classes = var.additional_priority_classes
}

module "storage_classes" {
  source = "./modules/storage-classes"

  additional_storage_classes = var.additional_storage_classes
}

resource "kubernetes_namespace" "default" {
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

  source = "./modules/rbac"
}

module "pod_identity" {
  depends_on = [
    kubernetes_namespace.default,
    module.priority_classes,
    module.storage_classes
  ]

  source = "./modules/pod-identity"

  resource_group_name          = var.resource_group_name
  namespace                    = "kube-system"
  aks_identity                 = var.aks_identity
  aks_node_resource_group_name = var.aks_node_resource_group_name
  network_plugin               = var.network_plugin
}

module "external_dns" {
  count      = (var.external_dns_zones == null ? 0 : 1)
  depends_on = [module.pod_identity]

  source = "./modules/external-dns"

  azure_tenant_id       = var.azure_tenant_id
  azure_subscription_id = var.azure_subscription_id

  resource_group_name = var.resource_group_name
  cluster_name        = var.cluster_name
  dns_zones           = var.external_dns_zones

  tolerations = [ {
    key   = "CriticalAddonsOnly"
    operator = "Equal"
    value    = "true"
    effect = "NoSchedule"
  }]

  tags = var.tags
}

module "cert_manager" {
  count      = (var.cert_manager_dns_zones == null ? 0 : 1)
  depends_on = [module.pod_identity]

  source = "./modules/cert-manager"

  azure_subscription_id = var.azure_subscription_id
  cluster_name        = var.cluster_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  dns_zones = var.cert_manager_dns_zones

  letsencrypt_environment = var.letsencrypt_environment
  letsencrypt_email       = var.letsencrypt_email
}