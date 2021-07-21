resource "kubernetes_storage_class" "default" {
  for_each = local.default_storage_classes

  metadata {
    name        = each.key
    labels      = each.value.labels
  }
  storage_provisioner    = each.value.storage_provisioner
  parameters             = each.value.parameters
  allow_volume_expansion = each.value.allow_volume_expansion
  reclaim_policy         = each.value.reclaim_policy
  mount_options          = each.value.mount_options
  volume_binding_mode    = each.value.volume_binding_mode
}
