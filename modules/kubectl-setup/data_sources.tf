data "http" "kubectl_latest" {
  count = (var.kubectl_version == null ? 1 : 0)
  url   = "https://dl.k8s.io/release/stable.txt"
}