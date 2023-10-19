output "cluster_id" {
  description = "ID of the Azure Kubernetes Service (AKS) managed cluster."
  value       = module.cluster.id
}

output "cluster_name" {
  description = "Name of the Azure Kubernetes Service (AKS) managed cluster."
  value       = module.cluster.cluster_name
}

output "cluster_version" {
  description = "Version of the Azure Kubernetes Service (AKS) managed cluster (<major>.<minor>)."
  value       = module.cluster.cluster_version
}

output "cluster_version_full" {
  description = "Full version of the Azure Kubernetes Service (AKS) managed cluster (<major>.<minor>.<patch>)."
  value       = module.cluster.cluster_version_full
}

output "latest_version_full" {
  description = "Latest full Kubernetes version the Azure Kubernetes Service (AKS) managed cluster could be on (<major>.<minor>.<patch>)."
  value       = module.cluster.latest_version_full
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

output "node_resource_group_name" {
  description = "Auto-generated resource group which contains the resources for this managed Kubernetes cluster."
  value       = module.cluster.node_resource_group_name
}

output "effective_outbound_ips" {
  description = "Outbound IPs from the Azure Kubernetes Service cluster managed load balancer (this will be an empty array if the cluster is uisng a user-assigned NAT Gateway)."
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

output "cert_manager_identity" {
  description = "Identity that Cert Manager uses."
  value       = module.core_config.cert_manager_identity
}

output "coredns_custom_config_map_name" {
  description = "Name of the CoreDNS custom ConfigMap."
  value       = module.core_config.coredns_custom_config_map_name
}

output "coredns_custom_config_map_namespace" {
  description = "Namespace of the CoreDNS custom ConfigMap."
  value       = module.core_config.coredns_custom_config_map_namespace
}

output "dashboards" {
  description = "Dashboards exposed."
  value       = module.core_config.dashboards
}

output "external_dns_private_identity" {
  description = "Identity that private ExternalDNS uses."
  value       = module.core_config.external_dns_private_identity
}

output "external_dns_public_identity" {
  description = "Identity that public ExternalDNS uses."
  value       = module.core_config.external_dns_public_identity
}

output "fluent_bit_aggregator_identity" {
  description = "Identity that Fluent Bit Aggregator uses."
  value       = module.core_config.fluent_bit_aggregator_identity
}

output "fluentd_identity" {
  description = "Identity that Fluentd uses."
  value       = module.core_config.fluentd_identity
}

output "grafana_identity" {
  description = "Identity that Grafana uses."
  value       = module.core_config.grafana_identity
}

output "internal_lb_source_ranges" {
  description = "All internal CIDRs."
  value       = module.core_config.internal_lb_source_ranges
}

output "oms_agent_identity" {
  description = "Identity that the OMS agent uses."
  value       = module.cluster.oms_agent_identity
}

output "windows_config" {
  description = "Windows configuration."
  value       = module.cluster.windows_config
}

output "kube_admin_config" {
  description = "Azure Kubernetes Service (AKS) kube_admin_config."
  value       = module.cluster.kube_admin_config
}
