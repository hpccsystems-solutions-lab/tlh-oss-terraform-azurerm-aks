resource "helm_release" "aad_pod_identity" {
  name       = "aad-pod-identity"
  namespace  = "kube-system"
  repository = "https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts"
  chart      = "aad-pod-identity"
  version    = local.helm_chart_version

  skip_crds = true

  values = [<<-EOT
---
rbac:
  allowAccessToSecrets: false
installCRDs: false
nmi:
  allowNetworkPluginKubenet: ${(var.network_plugin == "kubenet" ? true : false)}
EOT
  ]
}