resource "helm_release" "default" {
  name      = local.name
  namespace = var.namespace

  repository = "https://grafana.github.io/helm-charts/"
  chart      = "loki"
  version    = local.chart_version
  skip_crds  = true

  max_history = 10
  timeout     = ceil(var.timeouts.helm_modify * 1.5)

  values = [
    yamlencode(local.chart_values)
  ]

  depends_on = [
    module.identity
  ]
}
