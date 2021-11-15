resource "kubectl_manifest" "resources" {
  for_each = local.resource_files

  yaml_body = file(each.value)
}

resource "kubectl_manifest" "resource_objects" {
  for_each = local.resource_objects

  yaml_body = yamlencode(each.value)
}

resource "helm_release" "default" {
  name      = "fluentd"
  namespace = local.namespace

  repository = "https://stevehipwell.github.io/helm-charts/"
  chart      = "fluentd-aggregator"
  version    = local.chart_version
  skip_crds  = true
  wait       = false

  values = [
    yamlencode(local.chart_values)
  ]

  timeout = 600
}