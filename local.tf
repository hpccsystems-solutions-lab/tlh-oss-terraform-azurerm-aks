locals {
  cluster_versions = {
    "1.19" = "1.19.7"
    "1.18" = "1.18.14"
    "1.17" = "1.17.16"
  }

  cluster_name = var.cluster_name
}