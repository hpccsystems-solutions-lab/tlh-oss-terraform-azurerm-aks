resource "kubectl_manifest" "clusterrolebindings" {
  for_each = fileset(path.module, "clusterrolebindings/*.yaml")

  yaml_body = file("${path.module}/${each.value}")
}