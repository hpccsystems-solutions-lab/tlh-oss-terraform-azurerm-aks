locals {
  kubectl_version = (var.kubectl_version == null ? data.http.kubectl_latest[0].body : "v${var.kubectl_version}")
}