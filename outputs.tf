output "cluster_id" {
  description = "Azure Kubernetes Service (AKS) managed cluster ID."
  value       = module.cluster.id
}

output "cluster_fqdn" {
  description = "FQDN of the Azure Kubernetes Service managed cluster."
  value       = module.cluster.fqdn
}

output "cluster_endpoint" {
  description = "Endpoint for the Azure Kubernetes Service managed cluster API server."
  value       = module.cluster.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for the Azure Kubernetes Service managed cluster API server."
  value       = module.cluster.certificate_authority_data
}

output "effective_outbound_ips" {
  description = "Outbound IPs from the Azure Kubernetes Service managed cluster."
  value       = module.cluster.effective_outbound_ips
}

output "cluster_identity" {
  description = "User assigned identity used by the cluster."
  value       = module.cluster.cluster_identity
}

output "kubelet_identity" {
  description = "Kubelet identity."
  value       = module.cluster.kubelet_identity
}

output "grafana_identity" {
  description = "Grafana identity."
  value       = module.core_config.grafana_identity
}

output "node_resource_group_name" {
  description = "Auto-generated resource group which contains the resources for this managed Kubernetes cluster."
  value       = module.cluster.node_resource_group_name
}

output "control_plane_log_analytics_workspace_id" {
  description = "ID of the default log analytics workspace created for control plane logs."
  value       = module.cluster.control_plane_log_analytics_workspace_id
}

output "control_plane_log_analytics_workspace_name" {
  description = "Name of the default log analytics workspace created for control plane logs."
  value       = module.cluster.control_plane_log_analytics_workspace_id
}

output "windows_config" {
  description = "Windows configuration."
  value       = module.cluster.windows_config
}
