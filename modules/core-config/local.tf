locals {
  core_namespaces = [
    "cert-manager",
    "cluster-health",
    "dns",
    "logging",
    "monitoring"
  ]

  namespaces = concat(local.core_namespaces, var.namespaces)
}