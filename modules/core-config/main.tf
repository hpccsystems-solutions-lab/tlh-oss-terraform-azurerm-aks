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

module "external_dns" {
  depends_on = [kubernetes_namespace.default]

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
  depends_on = [kubernetes_namespace.default]

  source = "./modules/cert-manager"

  azure_subscription_id = var.azure_subscription_id
  cluster_name        = var.cluster_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  dns_zone = var.cert_manager_dns_zone

  letsencrypt_environment = var.letsencrypt_environment
  letsencrypt_email       = var.letsencrypt_email
}