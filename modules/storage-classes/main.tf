# resource "null_resource" "delete_aks_built_in_storage_classes" {
#   for_each = local.aks_built_in_storage_classes

#   provisioner "local-exec" {
#     command = "kubectl delete storageclasses.storage.k8s.io ${each.value}"
#   }
# }

# resource "kubernetes_storage_class" "cluster_default" {
#   metadata {
#     name = "azure-disk-standard-ssd-retain"
#     labels = local.standard_storage_class_labels
#     annotations = merge(
#       map("storageclass.kubernetes.io/is-default-class", "true"),
#       local.standard_storage_class_annotations
#     )
#   }
#   storage_provisioner = local.storage_provisioner
#   parameters = {
#     cachingmode        = "ReadOnly"
#     kind               = "Managed"
#     storageaccounttype = "StandardSSD_LRS"
#   }
#   allow_volume_expansion = true
#   reclaim_policy = "Retain"
#   mount_options = ["debug"]
#   volume_binding_mode = "WaitForFirstConsumer"

#   depends_on = [null_resource.delete_aks_built_in_storage_classes]
# }

resource "kubernetes_storage_class" "merged_storage_classes" {
  for_each = local.merged_storage_classes

  metadata {
    name = each.key
    labels = each.value.labels
    annotations = each.value.annotations
  }
  storage_provisioner = each.value.storage_provisioner
  parameters = each.value.parameters
  allow_volume_expansion = each.value.allow_volume_expansion
  reclaim_policy = each.value.reclaim_policy
  mount_options = each.value.mount_options
  volume_binding_mode = each.value.volume_binding_mode

  # depends_on = [null_resource.delete_aks_built_in_storage_classes]
}