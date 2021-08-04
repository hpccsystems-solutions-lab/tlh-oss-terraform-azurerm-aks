locals {
  cluster_name = var.cluster_name

  cluster_patch_matrix = {
    "1.21" = "1.21.2"
    "1.20" = "1.20.7"
    "1.19" = "1.19.11"
  }

  cluster_patch_version = local.cluster_patch_matrix[var.cluster_version]

  network_profile_options = {
    docker_bridge_cidr = "172.17.0.1/16"
    dns_service_ip     = "172.20.0.10"
    service_cidr       = "172.20.0.0/16"
  }

  network_plugin = lower(var.network_plugin)
}
