locals {
  cluster_patch_version = {
    "1.19" = "1.19.7"
    "1.18" = "1.18.14"
    "1.17" = "1.17.16"
  }

  cluster_version = local.cluster_patch_version[var.cluster_version]

  cluster_name = var.cluster_name

  network_plugin = lower(var.network_plugin)
}