resource "helm_release" "default" {
  name      = "node-config"
  namespace = var.namespace

  repository = "oci://ghcr.io/stevehipwell/helm-charts"
  chart      = "node-config"
  version    = local.chart_version
  skip_crds  = true

  max_history = 10
  timeout     = var.timeouts.helm_modify

  values = [
    yamlencode(local.chart_values)
  ]
}
