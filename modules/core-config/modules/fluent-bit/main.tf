resource "kubectl_manifest" "resources" {
  for_each = local.resource_files

  yaml_body = file(each.value)
}

resource "kubectl_manifest" "resource_objects" {
  for_each = local.resource_objects

  yaml_body = yamlencode(each.value)
}

resource "helm_release" "default" {
  name      = "fluent-bit"
  namespace = local.namespace

  repository = "https://fluent.github.io/helm-charts/"
  chart      = "fluent-bit"
  version    = local.chart_version
  skip_crds  = true

  values = [
    yamlencode(local.chart_values)
  ]

  timeout = 600
}