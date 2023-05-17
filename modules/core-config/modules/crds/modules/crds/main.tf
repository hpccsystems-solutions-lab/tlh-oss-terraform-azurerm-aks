resource "kubectl_manifest" "crds" {
  for_each = local.crd_files

  yaml_body = file(each.value)

  server_side_apply = true
  wait              = true
}
