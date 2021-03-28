output "kube_config" {
  value = module.kubernetes.kube_config
}

output "aks_cluster_name" {
  value = module.kubernetes.name
}