output "kube_config" {
  value = module.kubernetes.kube_config
}

output "aks_cluster_name" {
  value = module.kubernetes.name
}

output "aks_cluster_effective_outbound_ips_ids" {
  value = module.kubernetes.effective_outbound_ips_ids
}

output "aks_cluster_outbound_ip" {
  value = module.kubernetes.cluster_outbound_ip
}
  
output "kubelet_identity" {
  value = module.kubernetes.kubelet_identity
}
 
