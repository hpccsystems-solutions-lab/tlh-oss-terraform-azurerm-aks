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

  depends_on = [kubernetes_namespace.default]
}

resource "kubernetes_config_map" "default" {
  depends_on = [kubernetes_namespace.default]

  for_each = var.configmaps

  metadata {
    name      = each.value.name
    namespace = each.value.namespace
  }

  data = each.value.data

  depends_on = [kubernetes_namespace.default]
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

  resource_group_name          = var.resource_group_name
  cluster_name                 = var.cluster_name
  dns_zone                     = var.dns_zone

  tolerations = [ {
    key   = "CriticalAddonsOnly"
    operator = "Equal"
    value    = "true"
    effect = "NoSchedule"
  }]

  tags = var.tags
}