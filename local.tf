locals {
  cluster_patch_version = {
    "1.20" = "1.20.7"
    "1.19" = "1.19.11"
    "1.18" = "1.18.19"
  }

  network_profile_options = {
    docker_bridge_cidr = "172.17.0.1/16"
    dns_service_ip     = "172.20.0.10"
    service_cidr       = "172.20.0.0/16"
  }

  cluster_version = local.cluster_patch_version[var.cluster_version]

  cluster_name = var.cluster_name

  network_plugin = lower(var.network_plugin)
}
