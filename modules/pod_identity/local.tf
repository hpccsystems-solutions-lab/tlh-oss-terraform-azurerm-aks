locals {
  helm_chart_version = "4.0.0"

  crds = toset([
    "AzureAssignedIdentity",
    "AzureIdentity",
    "AzureIdentityBinding",
    "AzurePodIdentityException"
  ])

  labels = yamldecode(<<-EOT
    app.kubernetes.io/managed-by: Terraform
    lnrs.io/run-level: "0"
    lnrs.io/run-class: default
    lnrs.io/cloud-provider: azure
    lnrs.io/service: aad-pod-identity
  EOT
  )

  # decode default crd manifests
  default_crd_manifests = [for manifest in split("---", data.http.crds.body) : yamldecode(manifest)]

  # merge in custom labels
  crd_manifests = { for manifest in local.default_crd_manifests : manifest.spec.names.kind => yamlencode({ for k, v in manifest :
  k => (k != "metadata" ? v : { for x, y in v : x => (x == "labels" ? merge(y, local.labels) : y) }) }) }

  # Decode helm chart list
  chart_raw = yamldecode(data.http.chart.body)

  # Pull out chart versions
  chart_data = local.chart_raw.entries.aad-pod-identity

  # Decode app version installed by helm chart
  app_version = [for release in local.chart_data : release.appVersion if release.version == local.helm_chart_version][0]
}