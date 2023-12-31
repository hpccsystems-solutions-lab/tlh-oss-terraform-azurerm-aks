resource "kubernetes_secret" "zerossl_eabsecret" {
  metadata {
    name      = "zerossl-eabsecret"
    namespace = var.namespace
  }

  type = "Opaque"

  binary_data = {
    "${local.zerossl_eab_secret_key}" = "${local.zerossl_eabsecret}"
  }
}

resource "helm_release" "default" {
  name      = "cert-manager"
  namespace = var.namespace

  repository = "https://charts.jetstack.io/"
  chart      = "cert-manager"
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

resource "kubectl_manifest" "resource_files" {
  for_each = local.resource_files

  yaml_body = file(each.value)

  server_side_apply = true
  wait              = true

  depends_on = [
    helm_release.default
  ]
}

resource "kubectl_manifest" "issuers" {
  for_each = local.issuers

  yaml_body = yamlencode(each.value)

  server_side_apply = true
  wait              = true

  depends_on = [
    kubernetes_secret.zerossl_eabsecret,
    helm_release.default
  ]
}
