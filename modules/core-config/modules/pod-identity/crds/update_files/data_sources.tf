data "http" "chart" {
  url = "https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts/index.yaml"
}

data "http" "crds" {
  url = "https://raw.githubusercontent.com/Azure/aad-pod-identity/v${local.app_version}/charts/aad-pod-identity/crds/crd.yaml"
}