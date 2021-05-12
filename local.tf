locals {
  cluster_patch_version = {
    "1.20" = "1.20.5"
    "1.19" = "1.19.9"
    "1.18" = "1.18.17"
  }

  cluster_version = local.cluster_patch_version[var.cluster_version]

  cluster_name = var.cluster_name

  network_plugin = lower(var.network_plugin)
}