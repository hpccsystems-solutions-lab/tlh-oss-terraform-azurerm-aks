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
    module.identity
  ]
}
