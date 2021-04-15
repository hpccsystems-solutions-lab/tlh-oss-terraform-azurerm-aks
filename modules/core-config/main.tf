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
  for_each = var.configmaps

  metadata {
    name      = each.value.name
    namespace = each.value.namespace
  }

  data = each.value.data

  depends_on = [kubernetes_namespace.default]
}

module "rbac" {
  source = "./modules/rbac"
}