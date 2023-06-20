resource "kubernetes_secret_v1" "secret_env" {
  count = length(var.secret_env) > 0 ? 1 : 0

  metadata {
    name      = "${local.name}-secret-env"
    namespace = var.namespace
  }

  type = "Opaque"

  data = var.secret_env
}

resource "kubectl_manifest" "resource_files" {
  for_each = local.resource_files

  yaml_body = file(each.value)

  server_side_apply = true
  wait              = true
}

resource "helm_release" "default" {
  name      = local.name
  namespace = var.namespace

  repository = "oci://ghcr.io/stevehipwell/helm-charts"
  chart      = "fluent-bit-aggregator"
  version    = local.chart_version
  skip_crds  = true

  max_history = 10
  timeout     = var.timeouts.helm_modify

  values = [
    yamlencode(local.chart_values)
  ]

  depends_on = [
    module.identity,
    kubernetes_secret_v1.secret_env
  ]
}
