resource "helm_release" "default" {
  name      = "local-volume-provisioner"
  namespace = local.namespace

  repository = "https://flachesis.github.io/sig-storage-local-static-provisioner/"
  chart      = "provisioner"
  version    = local.chart_version

  values = [
    yamlencode(local.chart_values)
  ]
}