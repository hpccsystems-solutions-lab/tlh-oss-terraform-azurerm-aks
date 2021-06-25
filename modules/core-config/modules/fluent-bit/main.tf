resource "kubectl_manifest" "resources" {
  for_each = fileset(path.module, "resources/*.yaml")

  yaml_body = file("${path.module}/${each.key}")
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
}