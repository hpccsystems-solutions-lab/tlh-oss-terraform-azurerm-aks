resource "helm_release" "default" {
  name      = "local-static-provisioner"
  namespace = var.namespace

  repository = "https://kubernetes-sigs.github.io/sig-storage-local-static-provisioner/"
  chart      = "local-static-provisioner"
  version    = local.chart_version
  skip_crds  = true

  max_history = 10
  timeout     = var.timeouts.helm_modify

  values = [
    yamlencode(local.chart_values)
  ]
}
