resource "kubectl_manifest" "resources" {
  for_each = local.resource_files

  yaml_body = file(each.value)

  server_side_apply = true
}

resource "kubectl_manifest" "resource_objects" {
  for_each = local.resource_objects

  yaml_body = yamlencode(each.value)

  server_side_apply = true
}

resource "helm_release" "default" {
  name      = "ingress-${local.name}"
  namespace = "ingress-${local.name}"

  repository = "https://kubernetes.github.io/ingress-nginx/"
  chart      = "ingress-nginx"
  version    = local.chart_version
  skip_crds  = true
  timeout    = local.chart_timeout

  values = [
    yamlencode(local.chart_values)
  ]
}
