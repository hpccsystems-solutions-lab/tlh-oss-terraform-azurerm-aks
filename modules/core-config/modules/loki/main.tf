resource "helm_release" "default" {
  name      = "loki"
  namespace = var.namespace

  repository = "https://grafana.github.io/helm-charts/"
  chart      = "loki"
  version    = local.chart_version
  skip_crds  = true

  max_history = 10
  timeout     = var.timeouts.helm_modify

  values = [
    yamlencode(local.chart_values)
  ]

  depends_on = [
    module.identity
  ]
}
