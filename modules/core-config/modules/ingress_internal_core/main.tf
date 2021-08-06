resource "helm_release" "default" {
  name      = "ingress-core-internal"
  namespace = "ingress-core-internal"

  repository = "https://kubernetes.github.io/ingress-nginx/"
  chart      = "ingress-nginx"
  version    = local.chart_version
  skip_crds  = true
  timeout    = local.chart_timeout

  values = [
    yamlencode(local.chart_values)
  ]
}
