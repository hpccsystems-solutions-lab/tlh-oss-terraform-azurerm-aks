resource "local_file" "crd" {
  for_each = local.crd_manifests

  filename = "${path.module}/../${each.key}.yaml"
  content  = each.value
}