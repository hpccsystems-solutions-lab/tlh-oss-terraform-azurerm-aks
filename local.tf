locals {
  module_version = "v1.0.0-beta.5"

  cluster_name = var.cluster_name

  cluster_patch_matrix = {
    "1.22" = "1.22.4"
    "1.21" = "1.21.7"
    "1.20" = "1.20.13"
    "1.19" = "1.19.13"
  }

  cluster_patch_version = local.cluster_patch_matrix[var.cluster_version]

  network_profile_options = {
    docker_bridge_cidr = "172.17.0.1/16"
    dns_service_ip     = "172.20.0.10"
    service_cidr       = "172.20.0.0/16"
  }

  network_plugin = lower(var.network_plugin)

  tags = merge(var.tags, {
    "lnrs.io;k8s-platform"             = "true"
    "lnrs.io;terraform"                = "true"
    "lnrs.io;terraform-module"         = "terraform-azurerm-aks"
    "lnrs.io;terraform-module-version" = local.module_version
  })
}
