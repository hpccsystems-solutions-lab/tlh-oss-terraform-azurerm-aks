locals {
  cluster_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.ContainerService/managedClusters/${var.cluster_name}"

  cluster_tags = join(" ", [for k, v in var.cluster_tags : "${k}=${v}"])
}
