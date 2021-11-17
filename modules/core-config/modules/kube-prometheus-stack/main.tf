## The CRDs are required by a number of other services so are installed separately (core-config/main.tf)
## Provided for future compatibility - not used within this submodule
resource "kubectl_manifest" "crds" {
  for_each = var.skip_crds ? {} : local.crd_files

  yaml_body = file(each.value)

  server_side_apply = true
}

resource "kubectl_manifest" "resources" {
  for_each = local.resource_files

  yaml_body = file(each.value)

  server_side_apply = true

  depends_on = [
    kubectl_manifest.crds
  ]
}

resource "helm_release" "default" {
  name      = "kube-prometheus-stack"
  namespace = local.namespace

  repository = "https://prometheus-community.github.io/helm-charts/"
  chart      = "kube-prometheus-stack"
  version    = local.chart_version
  skip_crds  = true

  values = [
    yamlencode(local.chart_values)
  ]

  depends_on = [
    kubectl_manifest.crds
  ]
}

resource "kubernetes_secret" "grafana_auth" {
  metadata {
    name      = local.grafana_auth_secret_name
    namespace = local.namespace
  }

  type = "Opaque"
  data = {
    "admin-user"     = "admin"
    "admin-password" = var.grafana_admin_password
  }
}
